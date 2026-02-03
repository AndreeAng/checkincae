const express = require("express");
const { z } = require("zod");
const bcrypt = require("bcryptjs");
const ExcelJS = require("exceljs");
const dayjs = require("dayjs");
const utc = require("dayjs/plugin/utc");
const timezone = require("dayjs/plugin/timezone");

const { prisma } = require("../lib/prisma");
const { requireAuth, requireRole } = require("../middleware/auth");

dayjs.extend(utc);
dayjs.extend(timezone);

const adminRouter = express.Router();

adminRouter.use(requireAuth);
adminRouter.use(requireRole("ADMIN"));

// WorkSites
adminRouter.post("/worksites", async (req, res, next) => {
  try {
    const schema = z.object({
      name: z.string().min(1),
    });
    const data = schema.parse(req.body);
    const workSite = await prisma.workSite.create({ data });
    return res.status(201).json(workSite);
  } catch (error) {
    return next(error);
  }
});

adminRouter.get("/worksites", async (req, res, next) => {
  try {
    const items = await prisma.workSite.findMany({
      orderBy: { name: "asc" },
    });
    return res.json(items);
  } catch (error) {
    return next(error);
  }
});

adminRouter.put("/worksites/:id", async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const schema = z.object({
      name: z.string().min(1),
    });
    const data = schema.parse(req.body);
    const workSite = await prisma.workSite.update({ where: { id }, data });
    return res.json(workSite);
  } catch (error) {
    return next(error);
  }
});

adminRouter.delete("/worksites/:id", async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.workSite.delete({ where: { id } });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

// Users
adminRouter.post("/users", async (req, res, next) => {
  try {
    const schema = z.object({
      fullName: z.string().min(1),
      username: z.string().min(3),
      password: z.string().min(6),
      role: z.enum(["ADMIN", "EMPLOYEE"]).optional(),
      workSiteId: z
        .preprocess((val) => (val === null ? null : Number(val)), z.number().int())
        .optional()
        .nullable(),
    });
    const data = schema.parse(req.body);
    const passwordHash = await bcrypt.hash(data.password, 10);

    const user = await prisma.user.create({
      data: {
        fullName: data.fullName,
        username: data.username,
        passwordHash,
        role: data.role || "EMPLOYEE",
        workSiteId: data.workSiteId || null,
      },
      include: { workSite: true },
    });

    return res.status(201).json(user);
  } catch (error) {
    return next(error);
  }
});

adminRouter.get("/users", async (req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      include: { workSite: true },
      orderBy: { fullName: "asc" },
    });
    return res.json(users);
  } catch (error) {
    return next(error);
  }
});

adminRouter.put("/users/:id", async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const schema = z.object({
      fullName: z.string().min(1).optional(),
      username: z.string().min(3).optional(),
      password: z
        .preprocess((val) => (val == null ? undefined : String(val)), z.string().min(6))
        .optional(),
      role: z.enum(["ADMIN", "EMPLOYEE"]).optional(),
      workSiteId: z
        .preprocess((val) => (val === null ? null : Number(val)), z.number().int())
        .nullable()
        .optional(),
    });
    const data = schema.parse(req.body);

    const updateData = {
      fullName: data.fullName,
      username: data.username,
      role: data.role,
      workSiteId: data.workSiteId,
    };

    if (data.password) {
      updateData.passwordHash = await bcrypt.hash(data.password, 10);
    }

    const user = await prisma.user.update({
      where: { id },
      data: updateData,
      include: { workSite: true },
    });

    return res.json(user);
  } catch (error) {
    return next(error);
  }
});

adminRouter.delete("/users/:id", async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.user.delete({ where: { id } });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

// Checkins
function buildCheckinFilters(query) {
  const schema = z.object({
    employeeId: z.string().optional(),
    type: z.enum(["IN", "OUT"]).optional(),
    from: z.string().optional(),
    to: z.string().optional(),
    // channel y client eliminados
  });

  const parsed = schema.parse(query);
  const where = {};

  if (parsed.employeeId) {
    where.userId = Number(parsed.employeeId);
  }

  if (parsed.type) {
    where.type = parsed.type;
  }

  if (parsed.from || parsed.to) {
    where.occurredAt = {};
    if (parsed.from) {
      where.occurredAt.gte = new Date(parsed.from);
    }
    if (parsed.to) {
      where.occurredAt.lte = new Date(parsed.to);
    }
  }

  // canal y cliente eliminados

  return where;
}

adminRouter.get("/checkins", async (req, res, next) => {
  try {
    const where = buildCheckinFilters(req.query);
    const items = await prisma.checkin.findMany({
      where,
      include: { user: true, workSite: true },
      orderBy: { occurredAt: "desc" },
    });
    return res.json(items);
  } catch (error) {
    return next(error);
  }
});

adminRouter.get("/checkins/export", async (req, res, next) => {
  try {
    const where = buildCheckinFilters(req.query);
    const items = await prisma.checkin.findMany({
      where,
      include: { user: true, workSite: true },
      orderBy: { occurredAt: "desc" },
    });

    const tz = process.env.TIMEZONE || "America/La_Paz";
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet("Registros");

    sheet.columns = [
      { header: "Fecha", key: "fecha", width: 12 },
      { header: "Hora", key: "hora", width: 10 },
      { header: "Usuario", key: "usuario", width: 24 },
      { header: "Tipo", key: "tipo", width: 10 },
      { header: "Foto", key: "foto", width: 40 },
      { header: "Actividad", key: "actividad", width: 40 },
      { header: "Ubicacion", key: "ubicacion", width: 28 },
    ];

    items.forEach((item) => {
      const date = dayjs(item.occurredAt).tz(tz);
      sheet.addRow({
        fecha: date.format("YYYY-MM-DD"),
        hora: date.format("HH:mm:ss"),
        usuario: item.user?.fullName || item.user?.username,
        tipo: item.type === "IN" ? "Ingreso" : "Salida",
        foto: item.photoUrl,
        actividad: item.activity,
        ubicacion: `${item.latitude}, ${item.longitude}`,
      });
    });

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    const stamp = dayjs().tz(tz).format("YYYYMMDD_HHmmss");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=reportesregistrocae_${stamp}.xlsx`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    return next(error);
  }
});

module.exports = { adminRouter };
