import { RequestHandler, NextFunction } from "express";
import * as _ from "lodash";
const Boom = require("boom");

import IRequest from "../interface/IRequest";
import IResponse from "../interface/IResponse";
import IUser from "../interface/IUser";
import UserSchema from "../models/usersModel";
import * as mongoose from "mongoose";

/**
 * @param FirstName
 * @param LastName
 * @param email
 * @param DOB
 * @param Bio
 * validation of data
 */
export const validateData: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  const params = _.merge(req.body, req.params);
  const emailIdRegEx: RegExp = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
  if (_.isUndefined(params.FirstName)) {
    const err = new Error("First Name is require!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }
  if (_.isUndefined(params.LastName)) {
    const err = new Error("Last Name is require!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }
  if (_.isUndefined(params.email) || !emailIdRegEx.test(params.email)) {
    const err = new Error("Invalid Email!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }
  if (_.isUndefined(params.DOB)) {
    const err = new Error("Date of Birth is require!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }
  if (new Date(params.DOB).toString() === "Invalid Date") {
    const err = new Error("Invalid Date of Birth format!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }
  if (_.isUndefined(params.Bio)) {
    const err = new Error("Bio is require!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }

  return next();
};

/**
 * Insert new user
 */
export const insertUser: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  const params = _.merge(req.body, req.params);
  const data: IUser = {
    FirstName: params.FirstName,
    LastName: params.LastName,
    email: params.email,
    DOB: params.DOB,
    Bio: params.Bio,
  };

  const userData = new UserSchema(data);

  try {
    const user = await userData.save();
    req.users = user;
  } catch (error) {
    console.log(error);
    const err = new Error("Server side error!!");
    return res.send(Boom.boomify(err, { statusCode: 500 }));
  }

  return next();
};

/**
 * Read users from database
 */
export const getAllUsers: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  // const params = _.merge(req.body, req.params);

  // let skip = 0,
  //   sort = 0,
  //   limit = 5;

  // if (!_.isUndefined(params.skip)) {
  //   skip = parseInt(params.skip) || 0;
  // }
  // if (!_.isUndefined(params.sort)) {
  //   sort = parseInt(params.sort) || 0;
  // }
  // if (!_.isUndefined(params.limit)) {
  //   limit = parseInt(params.limit) || 5;
  // }

  try {
    const data = UserSchema.find({ isDel: 0 });

    data.select("_id FirstName LastName email DOB Bio");
    // data.limit(limit);
    // data.skip(skip);
    // data.sort({ FirstName: sort });

    req.users = await data.exec();

    return next();
  } catch (error) {
    console.log(error);
    const err = new Error("Server side error!!");
    return res.send(Boom.boomify(err, { statusCode: 500 }));
  }
};

/**
 * @param _id required
 * Delete user
 * Not actually update isDel 0 to 1
 */
export const deleteUser: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  const params = _.merge(req.body, req.params);

  if (_.isUndefined(params.id) || !mongoose.Types.ObjectId.isValid(params.id)) {
    const err = new Error("ID is invalid!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }

  const _id = params.id;

  try {
    const response = await UserSchema.findByIdAndUpdate(
      { _id, isDel: 0 },
      { isDel: 1 }
    );

    console.log(response);
    req.users = _.isNull(response)
      ? `User with id ${_id} is not found!!`
      : `User with id ${_id} is deleted!!`;

    return next();
  } catch (error) {
    console.log(error);
    const err = new Error("Server side error!!");
    return res.send(Boom.boomify(err, { statusCode: 500 }));
  }
};

/**
 * @param _id required
 * Update user
 */
export const updateUser: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  const params = _.merge(req.body, req.params);

  if (_.isUndefined(params.id) || !mongoose.Types.ObjectId.isValid(params.id)) {
    const err = new Error("ID is invalid!!");
    return res.send(Boom.boomify(err, { statusCode: 400 }));
  }

  const _id = params.id;

  const data: IUser = {
    FirstName: params.FirstName,
    LastName: params.LastName,
    email: params.email,
    DOB: params.DOB,
    Bio: params.Bio,
  };

  try {
    const response = await UserSchema.findByIdAndUpdate(
      { _id, isDel: 0 },
      data
    );

    console.log(response);
    req.users = _.isNull(response)
      ? `User with id ${_id} is not found!!`
      : `User with id ${_id} is updated!!`;

    return next();
  } catch (error) {
    console.log(error);
    const err = new Error("Server side error!!");
    return res.send(Boom.boomify(err, { statusCode: 500 }));
  }
};
