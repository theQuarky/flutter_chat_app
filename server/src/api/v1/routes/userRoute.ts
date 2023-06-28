import { Router } from "express";

import * as userServices from "../services/userServices.ts";
import * as userController from "../controllers/userControllers.ts";
const user: Router = Router();

user.post("/insert", [
  userServices.validateInsertData,
  userServices.insertData,
  userController.addUserController,
]);

user.post('/update',[
  userServices.getData,
  userServices.updateUser,
  userController.updateUserController
])

user.get("/get", [
  userServices.validateUserUid,
  userServices.getData,
  userController.getUserController,
]);

user.all("/", (req, res, next) => {
  console.log("user route");
  res.status(200).send("user route");
});
export default user;
