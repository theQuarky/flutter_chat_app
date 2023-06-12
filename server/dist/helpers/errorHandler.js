"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.internalServerError = exports.notFound = void 0;
const httpStatus = require("http-status");
// handle not found errors
const notFound = (req, res, next) => {
    res.status(httpStatus.NOT_FOUND);
    res.json({
        success: false,
        message: 'Requested Resource Not Found'
    });
    res.end();
};
exports.notFound = notFound;
// handle internal server errors
const internalServerError = (err, req, res, next) => {
    res.status(err.status || httpStatus.INTERNAL_SERVER_ERROR);
    res.json({
        message: err.message,
        extra: err.extra,
        errors: err
    });
    res.end();
};
exports.internalServerError = internalServerError;
//# sourceMappingURL=errorHandler.js.map