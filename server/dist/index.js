"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const App_1 = require("./App");
const config_1 = require("./config/config");
// import './config/db';
const PORT = config_1.default.PORT;
App_1.default.listen(PORT, () => {
    console.log(`Server is listening on http://127.0.0.1:${PORT}`);
});
//# sourceMappingURL=index.js.map