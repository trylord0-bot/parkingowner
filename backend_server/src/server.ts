import "dotenv/config";
import { buildApp } from "./app.js";
import { config } from "./config/index.js";
import { startCronJobs } from "./services/cron.js";

async function main() {
  const app = await buildApp();

  await app.listen({ port: config.PORT, host: "0.0.0.0" });
  app.log.info(`🅿️  ParkingOwner API running on port ${config.PORT}`);

  startCronJobs(app);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
