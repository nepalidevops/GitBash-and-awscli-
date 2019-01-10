package roadshow;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.MatcherAssert.assertThat;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.By;

import java.util.concurrent.TimeUnit;

import io.github.bonigarcia.Arguments;
import io.github.bonigarcia.DriverCapabilities;
import io.github.bonigarcia.DriverUrl;
import io.github.bonigarcia.SeleniumExtension;
import io.github.bonigarcia.wdm.WebDriverManager;

@ExtendWith(SeleniumExtension.class)
public class TestGoogleIT {

        @DriverUrl
        private static final String url = "http://127.0.0.1:4444/wd/hub";

        @BeforeAll
        public static void setUp() {
                WebDriverManager.chromedriver().setup();
        }

    @Test
    public void testChromeGrid(@Arguments("--headless") @DriverCapabilities("browserName=chrome") RemoteWebDriver driver) {
        performTest(driver);
    }

    @Test
    public void testFirefoxGrid(@Arguments("--headless") @DriverCapabilities("browserName=firefox") RemoteWebDriver driver) {
        performTest(driver);
    }

    private void performTest(WebDriver wd) {
        wd.get(System.getProperty("url"));
        wd.manage().timeouts().implicitlyWait(30,TimeUnit.SECONDS);
        assertThat("could not find string", wd.findElement(By.xpath("//h2[.='DaaS Automation Framework']")) != null);
    }
}