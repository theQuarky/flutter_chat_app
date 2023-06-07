import * as mongoose from "mongoose";
import CONFIG from "./config";

mongoose.set("useCreateIndex", true);

// Connecting to the database
export default (async () => {
  try {
    await mongoose.connect(CONFIG.DBURL, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    // listen for requests
    console.log("The Connection is Ok");
  } catch (err) {
    console.log(`${err} Could not Connect to the Database. Exiting Now...`);
    process.exit();
  }
})();
