import { Request } from 'express';
import IUser from './IUser.ts';


export default interface IRequest extends Request {
  token?: string;
  user?:IUser|IUser[];
}
