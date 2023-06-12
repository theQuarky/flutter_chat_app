import { Router, NextFunction } from "express";
import * as _ from "lodash";
import * as userController from "../controller/userController";
import * as userService from "../service/userService";

const user: Router = Router();

user.get("/", (req, res) => {
  return res.send("Hello");
});

user.post('/sendNotification',[
  userService.validateNotificationParams,
  userService.sendNotification,
]);

export default user;
