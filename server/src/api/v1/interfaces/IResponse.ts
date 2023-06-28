import { Response } from "express";
import IUser from "./IUser.ts";

export default interface IResponse extends Response{
    user?:IUser|IUser[];
    message?:String
}