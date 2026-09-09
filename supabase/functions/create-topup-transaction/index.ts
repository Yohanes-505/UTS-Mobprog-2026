import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY")!;
const IS_PRODUCTION = Deno.env.get("MIDTRANS_IS_PRODUCTION") === "true";

const MIDTRANS_SNAP_URL = IS_PRODUCTION
  ? "https://app.midtrans.com/snap/v1/transactions"
  : "https://app.sandbox.midtrans.com/snap/v1/transactions";

const MIN_TOPUP = 10000;
const MAX_TOPUP = 5000000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { amount } = await req.json();

    if (!amount || typeof amount !== "number" || amount < MIN_TOPUP || amount > MAX_TOPUP) {
      return jsonResponse(
        { error: `Jumlah top up harus antara Rp ${MIN_TOPUP} - Rp ${MAX_TOPUP}` },
        400,
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized: token tidak ditemukan" }, 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const jwt = authHeader.replace("Bearer ", "");
    const { data: userData, error: userError } = await supabase.auth.getUser(jwt);

    if (userError || !userData?.user) {
      return jsonResponse({ error: "Unauthorized: token tidak valid" }, 401);
    }

    const userId = userData.user.id;
    const orderId = `TOPUP-${userId.slice(0, 8)}-${Date.now()}`;

    const { error: insertError } = await supabase.from("transactions").insert({
      user_id: userId,
      order_id: orderId,
      type: "topup",
      tier: null,
      amount: amount,
      payment_status: "pending",
    });

    if (insertError) {
      console.error("Insert transaction error:", insertError);
      return jsonResponse({ error: "Gagal menyimpan transaksi" }, 500);
    }

    const midtransPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      credit_card: { secure: true },
      customer_details: {
        email: userData.user.email,
      },
      item_details: [
        {
          id: "topup",
          price: amount,
          quantity: 1,
          name: "Top Up Saldo Bumble",
        },
      ],
    };

    const authString = btoa(`${MIDTRANS_SERVER_KEY}:`);

    const midtransResponse = await fetch(MIDTRANS_SNAP_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${authString}`,
      },
      body: JSON.stringify(midtransPayload),
    });

    const midtransResult = await midtransResponse.json();

    if (!midtransResponse.ok) {
      console.error("Midtrans error:", midtransResult);
      await supabase
        .from("transactions")
        .update({ payment_status: "deny", midtrans_response: midtransResult })
        .eq("order_id", orderId);
      return jsonResponse({ error: "Gagal membuat transaksi Midtrans" }, 500);
    }

    await supabase
      .from("transactions")
      .update({
        snap_token: midtransResult.token,
        midtrans_response: midtransResult,
      })
      .eq("order_id", orderId);

    return jsonResponse({
      snap_token: midtransResult.token,
      redirect_url: midtransResult.redirect_url,
      order_id: orderId,
    });
  } catch (err) {
    console.error("Unexpected error:", err);
    return jsonResponse({ error: "Terjadi kesalahan tak terduga" }, 500);
  }
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}