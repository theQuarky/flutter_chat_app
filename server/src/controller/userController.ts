import { RequestHandler, NextFunction } from "express";
import IRequest from "../interface/IRequest";
import IResponse from "../interface/IResponse";

export const userInsert: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  res.send({
    user: req.users,
  });
};

export const getUsers: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  res.send({
    user: req.users,
  });
};

export const deleteUsers: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  res.send({
    user: req.users,
  });
};

export const updateUsers: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  res.send({
    user: req.users,
  });
};
