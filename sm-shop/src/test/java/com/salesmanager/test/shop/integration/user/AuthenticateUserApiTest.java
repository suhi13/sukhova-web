package com.salesmanager.test.shop.integration.user;

import com.salesmanager.test.shop.common.ServicesTestSupport;
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import org.apache.http.HttpStatus;
import org.junit.Assert;
import org.junit.Test;

import java.util.List;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.not;

public class AuthenticateUserApiTest extends ServicesTestSupport {

    String username = "admin@shopizer.com";
    String password = "password";
    String BASE_URL = "https://shopizer-api.rootin.cc";
    String token = getToken();

    RequestSpecification requestSpecification = new RequestSpecBuilder()
            .setBaseUri(BASE_URL)
            .addHeader("Authorization", "Bearer " + token)
            .setContentType(ContentType.JSON)
            .build();

    @Test
    public void checkThatNewTokenIsValid() {

        String refreshedToken = refreshToken();

        List<String> customersList = given()
                .baseUri(BASE_URL)
                .header("Authorization", "Bearer " + refreshedToken)
                .get("/api/v1/private/customers")
                .then()
                .statusCode(HttpStatus.SC_OK)
                .body("$", not(empty()))
                .contentType(ContentType.JSON)
                .extract().response().jsonPath().getList("customers");

        Assert.assertNotEquals("List of customers is empty", 0, customersList.size());
    }

    @Test
    public void checkThatTokenIsRefreshed() {

        String token = getToken();
        String refreshedToken = refreshToken();

        Assert.assertNotEquals("Token is not updated", token, refreshedToken);
    }

    public String refreshToken() {

        return (String) given()
                .spec(requestSpecification)
                .get("/api/v1/auth/refresh")
                .then()
                .statusCode(HttpStatus.SC_OK)
                .body("$", not(empty()))
                .contentType(ContentType.JSON)
                .extract().response()
                .jsonPath()
                .getMap("").get("token");
    }

    public String getToken() {

        return (String) given()
                .contentType(ContentType.JSON)
                .body(Map.of("password", password, "username", username))
                .post(BASE_URL + "/api/v1/private/login")
                .then()
                .statusCode(HttpStatus.SC_OK)
                .extract().response()
                .jsonPath()
                .getMap("").get("token");
    }
}