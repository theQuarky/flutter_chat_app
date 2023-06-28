import { Router } from 'express';
import users from './routes/userRoute.ts';

const router: Router = Router();

router.use('/users', users);

export default router;