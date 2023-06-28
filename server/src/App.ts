import express, { Application, Request, Response, NextFunction } from "express";
import mongoose from "npm:mongoose";
import helmet from "npm:helmet";
import morgan from "npm:morgan";
// import cors from "node:cors";
import apiV1 from "./api/v1/index.ts";
import * as jsYamlPort from "https://deno.land/x/js_yaml_port@3.14.0/js-yaml.js";
import IRequest from "./api/v1/interfaces/IRequest.ts";
import IResponse from "./api/v1/interfaces/IResponse.ts";
import swaggerJsdoc from 'npm:swagger-jsdoc';
import swaggerUi from 'npm:swagger-ui-express';

const swaggerDocument = jsYamlPort.load('api.yml');

class App {
  private app: Application;

  constructor() {
    this.app = express();
    this.connectToDatabase();
    this.configureMiddleware();
    this.configureRoutes();
    this.configureErrorHandling();
  }

  private connectToDatabase(): void {
    if (Deno.env.get("DB_URL")) {
      mongoose
        .connect(Deno.env.get("DB_URL"))
        .then(() => {
          console.log("Connected to MongoDB");
        })
        .catch((error) => {
          console.error("Failed to connect to MongoDB", error);
        });
    }
  }

  private configureMiddleware(): void {
    this.app.use(express.json());
    // this.app.use(cors());
    this.app.use(helmet()); // Security-related middleware
    this.app.use(morgan("combined")); // Logging middleware
    this.showReqBody();
    this.app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

    // Add any additional middleware setup here
  }

  private showReqBody(): void {
    this.app.use((req: IRequest, _res: Response, next: NextFunction) => {
      console.table(req.body);
      console.log(req.path);
      next();
    });
  }

  private configureRoutes(): void {
    this.app.get("/", (req: IRequest, res: IResponse) => {
      res.send("Hello, world!");
    });
    this.app.use('/v1',apiV1);
    // Add additional routes here
  }

  private configureErrorHandling(): void {
    // Custom error handling middleware
    this.app.use(
      (err: any, req: Request, res: Response, next: NextFunction) => {
        console.error(err.stack);
        res.status(500).send("Internal Server Error");
      }
    );

    // 404 Not Found middleware
    this.app.use((req: Request, res: Response, next: NextFunction) => {
      res.status(404).send("Not Found");
    });
  }
  private configureSwagger(): void {
    const options = {
      definition: {
        openapi: '3.0.0',
        info: {
          title: 'Your API Title',
          version: '1.0.0',
          description: 'Your API Description',
        },
      },
      apis: ['index.ts'], // Add other relevant files if needed
    };

    const specs = swaggerJsdoc(options);
    this.app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
  }
  public getApp(): Application {
    return this.app;
  }
}

export default new App().getApp();
