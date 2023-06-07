import * as bodyParser from "body-parser";
import * as cors from "cors";
import * as express from "express";
import apiV1 from "./api/index";
import * as errorHandler from "./helpers/errorHandler";
const boom = require("express-boom");
import IRequest from "./interface/IRequest";
import IResponse from "./interface/IResponse";
import { NextFunction } from "express";
import * as _ from "lodash";

class App {
  public express: express.Application;

  constructor() {
    this.express = express();
    this.setMiddleware();
    this.setRoutes();
    this.catchErrors();
    // this.connectToDatabase();
  }

  private setMiddleware(): void {
    this.express.use(cors());
    this.express.use(bodyParser.json());
    this.express.use(bodyParser.urlencoded({ extended: false }));
    this.express.use("/static", express.static("uploads"));
    this.express.use(cors());
    this.express.use(boom());
    this.express.use((req: IRequest, res: IResponse, next: NextFunction) => {
      const params = _.merge(req.body, req.params);
      console.table(params);
      return next();
    });
  }

  private setRoutes(): void {
    this.express.use("/v1", apiV1);
  }

  private catchErrors(): void {
    this.express.use(errorHandler.notFound);
    this.express.use(errorHandler.internalServerError);
  }

  // private connectToDatabase(): void {
  //   connection
  //     .connect()
  //     .then(() => {
  //       console.log("Connected to the database!");
  //     })
  //     .catch((err) => {
  //       console.log("Cannot connect to the database!", err);
  //       process.exit();
  //     });
  // }
}

export default new App().express;
