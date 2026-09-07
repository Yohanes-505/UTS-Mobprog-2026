import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY")!;

// 2. Hardcode URL Sandbox (agar dijamin 100% tidak lari ke server Production)
const MIDTRANS_SNAP_URL = "https://app.sandbox.midtrans.com/snap/v1/transactions";

const TIER_PRICES: Record<string, number> = {
  plus: 29000,
  premium: 59000,
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { tier } = await req.json();

    if (!tier || !TIER_PRICES[tier]) {
      return jsonResponse({ error: "Tier tidak valid." }, 400);
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
    const amount = TIER_PRICES[tier];
    const orderId = `SUB-${tier.toUpperCase()}-${userId.slice(0, 8)}-${Date.now()}`;

    const { error: insertError } = await supabase.from("transactions").insert({
      user_id: userId,
      order_id: orderId,
      tier: tier,
      amount: amount,
      payment_status: "pending",
    });

    if (insertError) {
      return jsonResponse({ error: "Gagal menyimpan transaksi" }, 500);
    }

    const midtransPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      credit_card: { secure: true },
      customer_details: {
        // Fallback email jika user auth belum punya email agar tidak ditolak Midtrans
        email: userData.user.email || "tester@datingapp.com",
        first_name: "DatingApp",
        last_name: "User"
      },
      item_details: [
        {
          id: tier,
          price: amount,
          quantity: 1,
          name: `Langganan - ${tier.toUpperCase()}`,
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
      // Kirim balik error asli dari Midtrans supaya kelihatan di HP jika masih gagal
      return jsonResponse({ error: `Midtrans: ${midtransResult.error_messages?.[0] || 'Gagal'}` }, 500);
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
    return jsonResponse({ error: "Terjadi kesalahan sistem" }, 500);
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