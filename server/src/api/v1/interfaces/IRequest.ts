import { Request } from 'express';
import IUser from './IUser';


export default interface IRequest extends Request {
  token?: string;
  user?:IUser|IUser[];
}
