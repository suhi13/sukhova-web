package com.salesmanager.test.shop.common;

import com.salesmanager.core.business.constants.Constants;
import com.salesmanager.shop.application.ShopApplication;
import com.salesmanager.shop.model.catalog.category.Category;
import com.salesmanager.shop.model.catalog.category.CategoryDescription;
import com.salesmanager.shop.model.catalog.category.PersistableCategory;
import com.salesmanager.shop.model.catalog.manufacturer.ManufacturerDescription;
import com.salesmanager.shop.model.catalog.manufacturer.PersistableManufacturer;
import com.salesmanager.shop.model.catalog.product.PersistableProduct;
import com.salesmanager.shop.model.catalog.product.ProductDescription;
import com.salesmanager.shop.model.catalog.product.ProductSpecification;
import com.salesmanager.shop.model.catalog.product.ReadableProduct;
import com.salesmanager.shop.model.shoppingcart.PersistableShoppingCartItem;
import com.salesmanager.shop.model.shoppingcart.ReadableShoppingCart;
import com.salesmanager.shop.store.security.AuthenticationRequest;
import com.salesmanager.shop.store.security.AuthenticationResponse;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import static org.springframework.http.HttpStatus.CREATED;
import static org.springframework.http.HttpStatus.OK;

@SpringBootTest(classes = ShopApplication.class, webEnvironment = WebEnvironment.RANDOM_PORT)
@ExtendWith(SpringExtension.class)
public class ServicesTestSupport {

    @Autowired
    protected TestRestTemplate testRestTemplate;

    protected HttpHeaders getHeader() {
        return getHeader("admin@shopizer.com", "password");
    }

    protected HttpHeaders getHeader(final String userName, final String password) {
        final ResponseEntity<AuthenticationResponse> response = testRestTemplate.postForEntity("/api/v1/private/login",
                new HttpEntity<>(new AuthenticationRequest(userName, password)), AuthenticationResponse.class);
        final HttpHeaders headers = new HttpHeaders();
        headers.setContentType(new MediaType("application", "json", StandardCharsets.UTF_8));
        headers.add("Authorization", "Bearer " + Objects.requireNonNull(response.getBody()).getToken());
        return headers;
    }

    protected PersistableManufacturer manufacturer(String code) {

      PersistableManufacturer m = new PersistableManufacturer();
      m.setCode(code);
      m.setOrder(0);

      ManufacturerDescription desc = new ManufacturerDescription();
      desc.setLanguage("en");
      desc.setName(code);

      m.getDescriptions().add(desc);

      return m;
    }

    protected PersistableCategory category() {

      PersistableCategory newCategory = new PersistableCategory();
      newCategory.setCode("TEST");
      newCategory.setSortOrder(1);
      newCategory.setVisible(true);
      newCategory.setDepth(1);

      CategoryDescription description = new CategoryDescription();
      description.setLanguage("en");
      description.setName("TEST");

      List<CategoryDescription> descriptions = new ArrayList<>();
      descriptions.add(description);

      newCategory.setDescriptions(descriptions);

      return newCategory;
    }

    protected PersistableProduct product(String code) {

      PersistableProduct product = new PersistableProduct();

      product.setPrice(BigDecimal.TEN);
      product.setSku(code);

      ProductDescription description = new ProductDescription();
      description.setName(code);
      description.setLanguage("en");

      product.getDescriptions().add(description);

      return product;
    }

    protected ReadableProduct sampleProduct(String code) {

        final PersistableCategory newCategory = new PersistableCategory();
        newCategory.setCode(code);
        newCategory.setSortOrder(1);
        newCategory.setVisible(true);
        newCategory.setDepth(4);

        final Category parent = new Category();

        newCategory.setParent(parent);

        final CategoryDescription description = new CategoryDescription();
        description.setLanguage("en");
        description.setName("test-cat");
        description.setFriendlyUrl("test-cat");
        description.setTitle("test-cat");

        final List<CategoryDescription> descriptions = new ArrayList<>();
        descriptions.add(description);

        newCategory.setDescriptions(descriptions);

        final HttpEntity<PersistableCategory> categoryEntity = new HttpEntity<>(newCategory, getHeader());

        final ResponseEntity<PersistableCategory> categoryResponse = testRestTemplate.postForEntity("/api/v1/private/category?store=" + Constants.DEFAULT_STORE, categoryEntity,
                PersistableCategory.class);
        final PersistableCategory cat = categoryResponse.getBody();
        Assertions.assertEquals(CREATED, categoryResponse.getStatusCode());
        Assertions.assertNotNull(Objects.requireNonNull(cat).getId());

        final PersistableProduct product = new PersistableProduct();
        final ArrayList<Category> categories = new ArrayList<>();
        categories.add(cat);
        product.setCategories(categories);
        ProductSpecification specifications = new ProductSpecification();
        specifications.setManufacturer(com.salesmanager.core.model.catalog.product.manufacturer.Manufacturer.DEFAULT_MANUFACTURER);
        product.setProductSpecifications(specifications);
        product.setAvailable(true);
        product.setPrice(BigDecimal.TEN);
        product.setSku(code);
        product.setQuantity(100);
        ProductDescription productDescription = new ProductDescription();
        productDescription.setDescription("TEST");
        productDescription.setName("TestName");
        productDescription.setLanguage("en");
        product.getDescriptions().add(productDescription);

        final HttpEntity<PersistableProduct> entity = new HttpEntity<>(product, getHeader());

        final ResponseEntity<PersistableProduct> response =
                testRestTemplate.postForEntity("/api/v1/private/product?store=" + Constants.DEFAULT_STORE, entity,
                        PersistableProduct.class);
        Assertions.assertEquals(CREATED, response.getStatusCode());

        final HttpEntity<String> httpEntity = new HttpEntity<>(getHeader());

        String apiUrl = "/api/v1/products/" + Objects.requireNonNull(response.getBody()).getId();

        ResponseEntity<ReadableProduct> readableProduct = testRestTemplate.exchange(apiUrl, HttpMethod.GET, httpEntity,
                ReadableProduct.class);
        Assertions.assertEquals(OK, readableProduct.getStatusCode());

        return readableProduct.getBody();
    }

    protected ReadableShoppingCart sampleCart() {

    	ReadableProduct product = sampleProduct("sampleCart");
    	Assertions.assertNotNull(product);

        PersistableShoppingCartItem cartItem = new PersistableShoppingCartItem();
        cartItem.setProduct(product.getId());
        cartItem.setQuantity(1);

        final HttpEntity<PersistableShoppingCartItem> cartEntity = new HttpEntity<>(cartItem, getHeader());
        final ResponseEntity<ReadableShoppingCart> response = testRestTemplate.postForEntity("/api/v1/cart/", 
                cartEntity, ReadableShoppingCart.class);

        Assertions.assertNotNull(response);
        Assertions.assertEquals(CREATED, response.getStatusCode());

    	return response.getBody();
    }
}