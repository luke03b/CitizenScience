package com.citizenScience.CitizenScienceBackend;

import com.citizenScience.repositories.AiContainerModelRepository;
import com.citizenScience.repositories.AiModelSelectionRepository;
import com.citizenScience.repositories.AvvistamentoRepository;
import com.citizenScience.repositories.FotoAvvistamentoRepository;
import com.citizenScience.repositories.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

/**
 * Smoke test that verifies the Spring application context assembles correctly.
 * All JPA repositories are mocked so no running database is required.
 */
@SpringBootTest(properties = {
        "spring.autoconfigure.exclude=" +
                "org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration," +
                "org.springframework.boot.hibernate.autoconfigure.HibernateJpaAutoConfiguration," +
                "org.springframework.boot.flyway.autoconfigure.FlywayAutoConfiguration," +
                "org.springframework.boot.data.jpa.autoconfigure.DataJpaRepositoriesAutoConfiguration",
        "jwt.secret=testSecretKeyForTestingOnlyWithMinimumLengthOf32Characters",
        "jwt.expiration=86400000",
        "ai.containers="
})
class CitizenScienceBackendApplicationTests {

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AvvistamentoRepository avvistamentoRepository;

    @MockitoBean
    private AiModelSelectionRepository aiModelSelectionRepository;

    @MockitoBean
    private AiContainerModelRepository aiContainerModelRepository;

    @MockitoBean
    private FotoAvvistamentoRepository fotoAvvistamentoRepository;

    @Test
    void contextLoads() {
    }

}
