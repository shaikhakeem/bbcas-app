require("dotenv").config();

const express = require("express");
const cors = require("cors");
const Stripe = require("stripe");

const app = express();
const PORT = process.env.PORT || 4242;

if (!process.env.STRIPE_SECRET_KEY) {
  console.error("Missing STRIPE_SECRET_KEY in .env");
  process.exit(1);
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

app.use(
  cors({
    origin: true,
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type"],
  })
);
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Stripe backend is running");
});

app.post("/create-checkout-session", async (req, res) => {
  try {
    const { orderId, totalAmount, successUrl, cancelUrl, items } = req.body;

    if (!orderId || !String(orderId).trim()) {
      return res.status(400).json({ error: "Missing orderId" });
    }

    if (!totalAmount || Number(totalAmount) <= 0) {
      return res.status(400).json({ error: "Invalid totalAmount" });
    }

    if (!successUrl || !cancelUrl) {
      return res.status(400).json({ error: "Missing successUrl or cancelUrl" });
    }

    const description =
      Array.isArray(items) && items.length > 0
        ? items
            .map((item) => `${item.quantity || 1} x ${item.name || "Menu Item"}`)
            .join(", ")
            .slice(0, 500)
        : "Restaurant order";

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      line_items: [
        {
          price_data: {
            currency: "aud",
            product_data: {
              name: `Burrito Bar Order ${orderId}`.trim(),
              description,
            },
            unit_amount: Math.round(Number(totalAmount) * 100),
          },
          quantity: 1,
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        orderId: String(orderId),
      },
    });

    res.json({ url: session.url });
  } catch (error) {
    console.error("Stripe session error:", error);
    res.status(500).json({
      error: error.message || "Failed to create checkout session",
    });
  }
});

app.listen(PORT, () => {
  console.log(`Stripe backend running on http://localhost:${PORT}`);
});