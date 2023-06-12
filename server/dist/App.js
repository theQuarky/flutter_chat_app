"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const bodyParser = require("body-parser");
const cors = require("cors");
const express = require("express");
const index_1 = require("./api/index");
const errorHandler = require("./helpers/errorHandler");
const _ = require("lodash");
class App {
    constructor() {
        this.express = express();
        this.setMiddleware();
        this.setRoutes();
        this.catchErrors();
        // this.connectToDatabase();
    }
    setMiddleware() {
        this.express.use(cors());
        this.express.use(bodyParser.json());
        this.express.use(bodyParser.urlencoded({ extended: false }));
        this.express.use("/static", express.static("uploads"));
        this.express.use(cors());
        this.express.use((req, res, next) => {
            const params = _.merge(req.body, req.params);
            console.table(params);
            return next();
        });
    }
    setRoutes() {
        this.express.use("/v1", index_1.default);
    }
    catchErrors() {
        this.express.use(errorHandler.notFound);
        this.express.use(errorHandler.internalServerError);
    }
}
exports.default = new App().express;
//# sourceMappingURL=App.js.map