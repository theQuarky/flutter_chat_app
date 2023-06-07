import * as express from "express";
import IUser from "./IUser";
export default interface IRequest extends express.Request {
  users?: IUser | IUser[] | any;
}
