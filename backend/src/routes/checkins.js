const express = require("express");
const { z } = require("zod");
const dayjs = require("dayjs");
const utc = require("dayjs/plugin/utc");
const timezone = require("dayjs/plugin/timezone");

const { prisma } = require("../lib/prisma");
const { requireAuth } = require("../middleware/auth");
const { upload } = require("../lib/upload");

dayjs.extend(utc);
dayjs.extend(timezone);

const checkinRouter = express.Router();

checkinRouter.post(
  "/",
  requireAuth,
  upload.single("photo"),
  async (req, res, next) => {
    try {
      const numberField = z
        .preprocess((val) => Number(val), z.number())
        .refine((val) => Number.isFinite(val), "numero_invalido");

      const schema = z.object({
        latitude: numberField,
        longitude: numberField,
        activity: z.string().min(1),
      });

      const { latitude, longitude, activity } = schema.parse(req.body);

      if (!req.file) {
        return res.status(400).json({ error: "foto_requerida" });
      }

      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        include: { workSite: true },
      });

      if (!user) {
        return res.status(404).json({ error: "usuario_no_encontrado" });
      }

      if (!user.workSiteId) {
        return res.status(400).json({ error: "usuario_sin_lugar_asignado" });
      }

      const lastCheckin = await prisma.checkin.findFirst({
        where: { userId: user.id },
        orderBy: { occurredAt: "desc" },
      });

      const type = lastCheckin?.type === "IN" ? "OUT" : "IN";
      const tz = process.env.TIMEZONE || "America/La_Paz";
      const occurredAt = dayjs().tz(tz).toDate();
      const uploadBase = process.env.UPLOAD_BASE_URL;
      const forwardedProto = req.get("x-forwarded-proto");
      const forwardedHost = req.get("x-forwarded-host");
      const originProto = forwardedProto || req.protocol;
      const originHost = forwardedHost || req.get("host");
      const dynamicBase = `${originProto}://${originHost}/uploads`;
      const base = (uploadBase || dynamicBase).replace(/\/$/, "");
      const photoUrl = `${base}/${req.file.filename}`;

      const checkin = await prisma.checkin.create({
        data: {
          userId: user.id,
          workSiteId: user.workSiteId,
          type,
          occurredAt,
          latitude,
          longitude,
          activity,
          photoUrl,
        },
        include: { workSite: true },
      });

      return res.status(201).json(checkin);
    } catch (error) {
      return next(error);
    }
  }
);

checkinRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const items = await prisma.checkin.findMany({
      where: { userId: req.user.id },
      include: { workSite: true },
      orderBy: { occurredAt: "desc" },
    });

    return res.json(items);
  } catch (error) {
    return next(error);
  }
});

module.exports = { checkinRouter };
