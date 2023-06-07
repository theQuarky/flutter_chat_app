import { Router, NextFunction } from "express";
import * as _ from "lodash";
import * as userController from "../controller/userController";
import * as userService from "../service/userService";

const user: Router = Router();

/**
 * End Point: URL/v1/user/ Method: Post
 * Inserting new User
 */
user.post("/", [
  userService.validateData,
  userService.insertUser,
  userController.userInsert,
]);

/**
 * End Point: URL/v1/user/ Method: Get
 * Read User data
 */
user.get("/", [userService.getAllUsers, userController.getUsers]);

/**
 * End Point: URL/v1/user/ Method: Delete
 * Delete user by id
 */
user.delete("/:id", [userService.deleteUser, userController.deleteUsers]);

/**
 * End Point: URL/v1/user/ Method: Put
 * Update user by id
 */
user.put("/:id", [
  userService.validateData,
  userService.updateUser,
  userController.updateUsers,
]);

export default user;
