import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.190.0/crypto/mod.ts";

const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY")!;

Deno.serve(async (req) => {
  try {
    const notification = await req.json();

    const {
      order_id,
      status_code,
      gross_amount,
      signature_key,
      transaction_status,
    } = notification;

    const raw = `${order_id}${status_code}${gross_amount}${MIDTRANS_SERVER_KEY}`;
    const expectedSignature = await sha512Hex(raw);

    if (expectedSignature !== signature_key) {
      console.error("Invalid signature for order:", order_id);
      return jsonResponse({ error: "Invalid signature" }, 403);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: trx, error: trxError } = await supabase
      .from("transactions")
      .select("*")
      .eq("order_id", order_id)
      .single();

    if (trxError || !trx) {
      console.error("Transaction not found:", order_id);
      return jsonResponse({ error: "Transaction not found" }, 404);
    }

    let newStatus = trx.payment_status;
    if (transaction_status === "settlement" || transaction_status === "capture") {
      newStatus = "settlement";
    } else if (transaction_status === "expire") {
      newStatus = "expire";
    } else if (transaction_status === "cancel" || transaction_status === "deny") {
      newStatus = transaction_status;
    }

    await supabase
      .from("transactions")
      .update({
        payment_status: newStatus,
        midtrans_response: notification,
        updated_at: new Date().toISOString(),
      })
      .eq("order_id", order_id);

    // Hindari nambah saldo dua kali kalau Midtrans kirim notifikasi
    // berulang untuk order_id yang sama (settlement dikirim lebih dari sekali)
    const alreadyCredited = trx.payment_status === "settlement";

    if (newStatus === "settlement" && !alreadyCredited && trx.type === "topup") {
      const { data: existingWallet } = await supabase
        .from("wallets")
        .select("balance")
        .eq("user_id", trx.user_id)
        .maybeSingle();

      if (existingWallet) {
        await supabase
          .from("wallets")
          .update({
            balance: existingWallet.balance + trx.amount,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", trx.user_id);
      } else {
        await supabase.from("wallets").insert({
          user_id: trx.user_id,
          balance: trx.amount,
        });
      }

      await supabase.from("wallet_transactions").insert({
        user_id: trx.user_id,
        type: "topup_credit",
        amount: trx.amount,
        description: `Top up via Midtrans (order ${order_id})`,
      });
    }

    return jsonResponse({ received: true });
  } catch (err) {
    console.error("Webhook error:", err);
    return jsonResponse({ error: "Terjadi kesalahan tak terduga" }, 500);
  }
});

async function sha512Hex(text: string): Promise<string> {
  const data = new TextEncoder().encode(text);
  const hashBuffer = await crypto.subtle.digest("SHA-512", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}