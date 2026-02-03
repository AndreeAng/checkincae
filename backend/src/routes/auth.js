const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { z } = require("zod");
const { prisma } = require("../lib/prisma");
const { requireAuth } = require("../middleware/auth");

const authRouter = express.Router();

authRouter.post("/login", async (req, res, next) => {
  try {
    const schema = z.object({
      username: z.string().min(1),
      password: z.string().min(1),
    });
    const { username, password } = schema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { username },
      include: { workSite: true },
    });

    if (!user) {
      return res.status(401).json({ error: "credenciales_invalidas" });
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ error: "credenciales_invalidas" });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: "12h" }
    );

    return res.json({
      token,
      user: {
        id: user.id,
        fullName: user.fullName,
        username: user.username,
        role: user.role,
        workSite: user.workSite,
      },
    });
  } catch (error) {
    return next(error);
  }
});

authRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { workSite: true },
    });

    if (!user) {
      return res.status(404).json({ error: "usuario_no_encontrado" });
    }

    return res.json({
      id: user.id,
      fullName: user.fullName,
      username: user.username,
      role: user.role,
      workSite: user.workSite,
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = { authRouter };
