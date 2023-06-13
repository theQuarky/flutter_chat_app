import { Document } from 'mongoose';

export default interface IUser extends Document {
  displayName: string;
  gender: string;
  dob: Date;
  deviceToken: string;
  friends: string[];
  isActive: boolean;
  imageUrl: string;
}
