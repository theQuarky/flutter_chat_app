"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const userService = require("../service/userService");
const user = (0, express_1.Router)();
user.get("/", (req, res) => {
    return res.send("Hello");
});
user.post('/sendNotification', [
    userService.validateNotificationParams,
    userService.sendNotification,
]);
exports.default = user;
//# sourceMappingURL=userRoute.js.map