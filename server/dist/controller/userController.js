"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateUsers = exports.deleteUsers = exports.getUsers = exports.userInsert = void 0;
const userInsert = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    res.send({
        user: req.users,
    });
});
exports.userInsert = userInsert;
const getUsers = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    res.send({
        user: "req.users",
    });
    // res.send({
    //   user: req.users,
    // });
});
exports.getUsers = getUsers;
const deleteUsers = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    res.send({
        user: req.users,
    });
});
exports.deleteUsers = deleteUsers;
const updateUsers = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    res.send({
        user: req.users,
    });
});
exports.updateUsers = updateUsers;
//# sourceMappingURL=userController.js.map