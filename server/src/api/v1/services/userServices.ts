import { NextFunction, RequestHandler } from "express";
import IRequest from "../interfaces/IRequest";
import IResponse from "../interfaces/IResponse";
import _ from "lodash";
import UserModal from "../models/UserModel";
import IUser from "../interfaces/IUser";

export const validateInsertData: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  try {
    const { displayName, gender, dob, imageUrl } = req.body;

    // Define required fields and their corresponding data types
    const requiredFields = [
      { field: "displayName", type: "string" },
      { field: "gender", type: "string" },
      { field: "dob", type: "string" },
      { field: "uid", type: "string" },
    ];

    const missingFields: String[] = [];
    const invalidFields: String[] = [];

    // Perform data validation using lodash
    _.forEach(requiredFields, ({ field, type }) => {
      if (!_.has(req.body, field)) {
        missingFields.push(field);
      } else if (typeof req.body[field] !== type) {
        invalidFields.push(field);
      }
    });

    if (missingFields.length > 0 || invalidFields.length > 0) {
      return res.status(400).json({
        error: "Invalid or missing fields",
        missingFields,
        invalidFields,
      });
    }
    next();
  } catch (error) {
    console.error("Error validating user data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const insertData: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  try {
    const { uid, displayName, gender, dob, imageUrl } = req.body;
    const user = new UserModal({
      uid,
      displayName,
      gender,
      dob,
      imageUrl,
    });
    const result = await user.save();
    req.user = result;
    return next();
  } catch (error) {
    console.error("Error inserting user data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const validateUserUid: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  try {
    const { uid } = req.query || req.body;
    if (!uid) {
      return res.status(400).json({
        error: "Invalid or missing fields",
      });
    }
    next();
  } catch (error) {
    console.error("Error validating user data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getData: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  try {
    const { uid } = _.merge(req.body,req.params, req.query);
    const user = await UserModal.findOne({ uid });
    if (!user) {
      return res.status(404).json({
        error: "User not found",
      });
    }
    req.user = user;
    return next();
  } catch (error) {
    console.error("Error getting user data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const updateUser: RequestHandler = async (
  req: IRequest,
  res: IResponse,
  next: NextFunction
) => {
  try {
    const { displayName, gender, dob, imageUrl } = req.body;

    const user:IUser|any = req.user;
    // Find the user in the database by UID

    // Update the user's properties with the provided data
    if (displayName) {
      user.displayName = displayName;
    }
    if (gender) {
      user.gender = gender;
    }
    if (dob) {
      user.dob = dob;
    }
    if (imageUrl) {
      user.imageUrl = imageUrl;
    }

    // Save the updated user data
    const updatedUser = await user.save();

    req.user = updatedUser;
    return next();
  } catch (error) {
    console.error("Error updating user data:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
