using Xunit;

namespace Fixture.Tests;

public static class Calculator
{
    public static int Add(int a, int b) => a + b;
}

public class CalculatorTests
{
    [Fact]
    public void AddsTwoNumbers()
    {
        Assert.Equal(4, Calculator.Add(2, 2));
    }
}
