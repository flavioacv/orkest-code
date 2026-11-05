// C# sample fixture
namespace Orkest.Sample;

public record Account(string Id, decimal Balance)
{
    public bool HasFunds(decimal amount) => Balance >= amount;
}
