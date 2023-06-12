"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendNotification = exports.validateNotificationParams = void 0;
const _ = require("lodash");
const admin = require("firebase-admin");
const serviceAccount = {
    type: "service_account",
    project_id: "flutter-c91c8",
    private_key_id: "eca954bf023aacfc7ffe72db11fe6b4ec458a23f",
    private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDO1PIcrl9SPm1D\nsekYWX4gjFqbvq237rhLyGNk85k7NOZTwloovb0ZDIx/8YemeDhMiys4mzUjsIev\nliubdKloSthwYiUlb9Vsi8rGbtur2veUHlGqtjrvPvuQeSi+6TQOM0ema+1KkKcZ\nAf9b/Vg/cUvbV9pDLDazqS+WEZxLTe+v+JNI9Hz8jvXc6EYt/beMfFPsE6a3oxQh\ntyOlhUxLSoqpqA3kufRvvaOjDvUbA2ARe7rVWb8pkhD711Qq0G30AsDjLNFC0EKs\nchetzYs5rfK8gfqub2gPQ6eyKRXoJNeD9+qtNdW9Qy3lbsL1FGHs1mHjvgM3O+b6\njgRwczJRAgMBAAECggEAAd/fm7IvtQ58XcYni/PoBFo/9M76eChoFUVpM4g60dTX\nHLhOFMtcbX/Qkv/GGD8ubnDT86jsxz3Riv44IgoW13YXMP84tuFFDJ1AjsIWMwAS\nk+4e6hvJnAhkzgXvwDmGQjXa2Zel5cc6wSD5zB8B4ohPtPq+ZLMKbLV/s93avhAg\nHt57a2nX70xNT7E17k0+v7jnESZdBPByHb21DJxYv3GGIbsze+FsSb9pvw10ELGp\nReagU16SzQgsCPzQoubfvqOO1rC+0sWbcqHzwOjldaqqmVmYZwUb4GiMk8vRzj01\n/6HqkLIP1PX+4JYoWGhlVAxmULf9ldImiZmnFstNwQKBgQD3bEgqPt/vYMptpEy+\ncenOe7e9XNlfUdrtrrBEFX7diYyGhjP6OrC5mqCC6xSai2pRlf+eZrR6VO86H8n/\nf3UafNmKx9IiiItFhl8ULwbiAUqTrLOYmaU9fRPzSnL+PMM4g+99eW9LavAHc+sP\nh7EMPecXNf/hY7sml8sMSuPnMQKBgQDWAHGXpqx6AixkvMYAzmjVMwobYHCH4drg\nBmGsMIxSOKMHIqU+mp0i1okdkqC1HdcZjdP5hcQQ+X+zib2Tt+fFY6vQ6SjcAwOK\n9EzagFh8w3WOgFdDO4WE6dIJ6zsRaZwZgmnI55OGqoo+ve5nhiOIo1MzSA4PhJAh\nmG4D7rl1IQKBgQDTEgiuIV0f9M47ooHlpX/zqg8g9+hoLIg7Y17zdfL4QrMiv7Hv\nscm5THPJu4mkHXLhjri2BJ/KDFLYnu3PjIf1xLRAdB6LXziQYwURTtzsSHW6bQX5\nFHmmbuFqFwTqZiOUPtk7jTCogd2qPfU1FmivLM/LOUHEoTOyxKNvJSQuwQKBgBXo\nQ7inml5/HHZPkOGCP98bc3xr+fkfGN34KUWMTsEYBTB0zn/DKjTny2+YlBUWce+u\nwjV4CSNHt1f00NBvci2Vz3/6bnFfaZxu9/MiUmyrQbyNzOEYFcoOea8EQq68pftC\ni3vCoSqXCMH1hZNZewfA2IKWbMIP6wVVamXCqX+hAoGANRcNbnjBD3JiOi7k4qrv\ngZKQy+45BYuE106fjLjYsxzpOEpPvEb2+VIu6AgMaAvL8AY0gcTXM4LxxFIdBZw5\n0zEareSiyor5uQJzI/+XK6tTAaRjXLF74V7N/WFG69ormNxgcjDkmSA1ly5iOWXG\nRFdV+iVToyWwRe+DsYjhjcs=\n-----END PRIVATE KEY-----\n",
    client_email: "firebase-adminsdk-lv5ea@flutter-c91c8.iam.gserviceaccount.com",
    client_id: "106623340619610354025",
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-lv5ea%40flutter-c91c8.iam.gserviceaccount.com",
    universe_domain: "googleapis.com",
};
admin.initializeApp({
    credential: admin.credential.cert({
        projectId: "flutter-c91c8",
        privateKey: serviceAccount.private_key,
        clientEmail: serviceAccount.client_email,
    }),
});
// Use the admin SDK methods here
const validateNotificationParams = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    const params = _.merge(req.body, req.params);
    if (_.isEmpty(params.token)) {
        return res.status(400).send("Token is required");
    }
    if (_.isEmpty(params.body)) {
        return res.status(400).send("Body is required");
    }
    if (_.isEmpty(params.title)) {
        return res.status(400).send("Title is required");
    }
    return next();
});
exports.validateNotificationParams = validateNotificationParams;
const sendNotification = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    const params = _.merge(req.body, req.params);
    const messaging = admin.messaging();
    const message = {
        token: params.token,
        notification: {
            title: params.title,
            body: params.body,
        },
    };
    messaging
        .send(message)
        .then((result) => {
        console.log("Result: ", result);
        return res.status(200).send({ message: "Notification send" });
    })
        .catch((err) => {
        console.log("Err: ", err);
        return res.status(400).send({ message: "Error occured while sending notificaiton" });
    });
});
exports.sendNotification = sendNotification;
//# sourceMappingURL=userService.js.map