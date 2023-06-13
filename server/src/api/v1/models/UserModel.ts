import mongoose, { Schema } from "mongoose";
import IUser from "../interfaces/IUser";

const UserSchema: Schema = new Schema(
  {
    uid: {
      type: String,
      required: true,
      unique: true,
    },
    displayName: {
      type: String,
      required: true,
    },
    gender: {
      type: String,
      enum: ["male", "female"],
      required: true,
    },
    dob: {
      type: Date,
      required: true,
    },
    deviceToken: {
      type: String,
    },
    friends: {
      type: [Object],
      default: [],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    imageUrl: {
      type: String,
      required: false,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

UserSchema.set("toJSON", {
  virtuals: true,
  transform: function (doc: any, ret: any) {
    delete ret._id;
  },
});

const UserModal = mongoose.model<IUser>("user", UserSchema);

export default UserModal;
