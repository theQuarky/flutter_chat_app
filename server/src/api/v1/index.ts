import { Router } from 'express';
import users from './routes/userRoute';

const router: Router = Router();

router.use('/users', users);

export default router;