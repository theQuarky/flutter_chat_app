import IResponse from "../interfaces/IResponse";
import IRequest from "../interfaces/IRequest";
import { RequestHandler } from "express";

export const addUserController: RequestHandler = async (
  req: IRequest,
  res: IResponse
) => {
  return res.status(200).send({
    user: req.user,
    message: "User added successfully!",
  });
};

export const getUserController: RequestHandler = async (
  req: IRequest,
  res: IResponse
) => {
  return res.status(200).send({
    user: req.user,
    message: "User get successfully!",
  });
};

export const updateUserController: RequestHandler = async (
  req: IRequest,
  res: IResponse
) => {
  return res.status(200).send({
    user: req.user,
    message: "User updated successfully!",
  });
}