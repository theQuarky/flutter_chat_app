"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const dotenv = require("dotenv");
dotenv.config();
const CONFIG = {
    APP: process.env.APP || 'development',
    PORT: process.env.PORT || '8000',
    DBURL: process.env.DBURL || "mongodb+srv://root:toor@cluster0.ooiba.mongodb.net/test?retryWrites=true&w=majority"
};
exports.default = CONFIG;
//# sourceMappingURL=config.js.map