"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const userRoute_1 = require("./userRoute");
const router = (0, express_1.Router)();
router.use("/users", userRoute_1.default);
exports.default = router;
//# sourceMappingURL=index.js.map