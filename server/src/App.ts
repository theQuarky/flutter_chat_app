import express, { Application, Request, Response, NextFunction } from "express";
import mongoose from "mongoose";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import cors from "cors";
import apiV1 from "./api/v1";
import YAML from 'yamljs';
import IRequest from "./api/v1/interfaces/IRequest";
import IResponse from "./api/v1/interfaces/IResponse";
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const swaggerDocument = YAML.load('api.yml');

dotenv.config();

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
    if (process.env.DB_URL) {
      mongoose
        .connect(process.env.DB_URL)
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
    this.app.use(cors());
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
