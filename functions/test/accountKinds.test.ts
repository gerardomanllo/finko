import {
  isLiabilityAccountType,
  openingBalanceDirectionForAccount,
} from "../src/accountKinds";

describe("accountKinds", () => {
  it("classifies liability types", () => {
    expect(isLiabilityAccountType("creditCard")).toBe(true);
    expect(isLiabilityAccountType("loan")).toBe(true);
    expect(isLiabilityAccountType("mortgage")).toBe(true);
    expect(isLiabilityAccountType("checking")).toBe(false);
    expect(isLiabilityAccountType(undefined)).toBe(false);
  });

  it("openingBalanceDirectionForAccount matches asset vs liability semantics", () => {
    expect(openingBalanceDirectionForAccount("checking", 100)).toBe("in");
    expect(openingBalanceDirectionForAccount("checking", -100)).toBe("out");
    expect(openingBalanceDirectionForAccount("creditCard", 100)).toBe("out");
    expect(openingBalanceDirectionForAccount("creditCard", -100)).toBe("in");
  });
});
