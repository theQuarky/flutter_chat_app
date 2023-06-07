import * as mongoose from "mongoose";
const UserSchema = new mongoose.Schema({
  FirstName: {
    type: String,
    required: true,
  },
  LastName: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    lowercase: true,
    required: true,
  },
  DOB: {
    type: Date,
    required: true,
  },
  Bio: {
    type: String,
    required: true,
  },
  isDel: {
    type: Number,
    default: 0,
    required: true,
  },
});

UserSchema.set("autoIndex", true);
export default mongoose.model("users", UserSchema);
