import * as dotenv from 'dotenv';
dotenv.config();

const CONFIG = {
  APP: process.env.APP || 'development',
  PORT: process.env.PORT || '8000',
  DBURL: process.env.DBURL || "mongodb+srv://root:toor@cluster0.ooiba.mongodb.net/test?retryWrites=true&w=majority"
};

export default CONFIG;