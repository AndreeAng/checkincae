const dotenv = require("dotenv");
const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  const username = process.env.ADMIN_USERNAME || "admin";
  const password = process.env.ADMIN_PASSWORD || "Admin123!";
  const fullName = process.env.ADMIN_FULLNAME || "Administrador";

  const existing = await prisma.user.findUnique({ where: { username } });
  if (existing) {
    console.log("El administrador ya existe.");
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await prisma.user.create({
    data: {
      fullName,
      username,
      passwordHash,
      role: "ADMIN",
    },
  });

  console.log("Administrador creado:", username);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
