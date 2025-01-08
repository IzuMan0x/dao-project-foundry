// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

//for future use
import "./interfaces/ITreasury.sol";
import "./interfaces/IWerewolfTokenV1.sol";
import "./interfaces/IDAO.sol";
import "./interfaces/ITokenSale.sol";

import "./Treasury.sol";
import "./WerewolfTokenV1.sol";
import "./DAO.sol";
import "./TokenSale.sol";

/* Contract layout:
 Data types: structs, enums, and type declarations
 State Variables
 Events
 Function Modifiers
 Constructor/Initialize
 Fallback and Receive function
 External functions
 Public functions
 Internal functions
 Private Functions
*/

contract CompaniesHouseV1 is AccessControlUpgradeable {
    ///////////////////////////////////////
    //           Data Types              //
    ///////////////////////////////////////
    struct CompanyStruct {
        uint256 companyId;
        address owner;
        string industry;
        string name;
        uint256 createdAt;
        bool active;
        address[] employees;
        string domain;
        string[] roles;
        string[] powerRoles;
    }

    struct Employee {
        uint256 salary;
        uint256 lastPayDate;
        uint256 employeeId;
        address payableAddress;
        string name;
        uint256 companyId;
        string role;
        uint256 hiredAt;
        bool active;
        string currency;
    }

    //currentl unused
    struct InventoryItem {
        uint256 salary;
        uint256 lastPayDate;
        uint256 employeeId;
        address payableAddress;
        string name;
        uint256 companyId;
        string role;
        uint256 hiredAt;
        bool active;
        string currency;
    }
    ///////////////////////////////////////
    //           State Variables         //
    ///////////////////////////////////////
    // TODO check to see if switching to interfaces saves gas

    WerewolfTokenV1 private werewolfToken;
    TokenSale public tokenSale;
    DAO public dao;
    Treasury public treasury;
    // CompanyV1 creator;
    // address owner;
    // string name;
    bytes32 public constant STAFF_ROLE = keccak256("CEO");
    uint256 public index; // Number of companies
    uint256 public employeesIndex; // Number of employees in company
    uint256 public amountToPay; // Amount to pay to create a business
    uint256 public fee;

    CompanyStruct[] public companies;
    // mapping(address => mapping(uint32 => CompanyStruct)) public companies;
    mapping(uint256 => CompanyStruct[]) public companiesByOwner;

    mapping(address => Employee) private _employees;
    address private _treasuryAddress;
    address private _owner;

    ///////////////////////////////////////
    //           Events                  //
    ///////////////////////////////////////
    event EmployeeHired(address indexed employee, uint256 salary);
    event EmployeeFired(address indexed employee);
    event EmployeePaid(address indexed employee, uint256 amount);
    event CompanyCreated(CompanyStruct company);
    event CompanyDeleted(CompanyStruct company);

    ///////////////////////////////////////
    //           Modifiers               //
    ///////////////////////////////////////
    modifier onlyRoleWithPower(uint256 _companyId) {
        // Ensure the caller is a member of the company
        Employee storage employee = _employees[msg.sender];
        require(employee.companyId == _companyId, "Not an employee of this company");

        bool hasPower = false;

        // Check if the employee's role is in the powerRoles list
        for (uint256 i = 0; i < companies[_companyId].powerRoles.length; i++) {
            if (
                keccak256(abi.encodePacked(companies[_companyId].powerRoles[i])) //mh need to make sure no company has id of 0
                    == keccak256(abi.encodePacked(employee.role))
            ) {
                hasPower = true;
                break;
            }
        }

        require(hasPower, "You do not have a power role in this company.");
        _;
    }
    ///////////////////////////////////////
    //      Constructor/Initializer      //
    ///////////////////////////////////////

    constructor() {
        //disable the implementation contracts initializer
        _disableInitializers();
    }

    /**
     * @notice Initializes the proxy's storage
     * @dev
     * @param _token address of the Wereworlf token
     * @param treasuryAddress address where all the funds and fees will be stored
     * @param _daoAddress privileged address
     * @param tokenSaleAddress the address that will handle the token sale
     */
    function initialize(address _token, address treasuryAddress, address _daoAddress, address tokenSaleAddress)
        public
        initializer
    {
        werewolfToken = WerewolfTokenV1(_token);
        dao = DAO(_daoAddress);
        tokenSale = TokenSale(tokenSaleAddress);
        treasury = Treasury(treasuryAddress);
        _treasuryAddress = treasuryAddress;

        //previously declared outside the constructor
        fee = 10;
        amountToPay = 10e18;

        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(STAFF_ROLE, msg.sender);
    }

    ///////////////////////////////////////
    //           Public Functions        //
    ///////////////////////////////////////

    function createCompany(
        string memory _name,
        string memory _industry,
        string memory _domain,
        string[] memory _roles,
        string[] memory _powerRoles,
        string memory _ownerName,
        string memory _ownerRole,
        uint256 _ownerSalary,
        string memory _ownerCurrency
    ) public {
        require(werewolfToken.balanceOf(msg.sender) >= amountToPay, "Token balance must be more than amount to pay.");
        require(werewolfToken.transferFrom(msg.sender, address(this), amountToPay), "Transfer failed.");

        address[] memory employeesArray;

        CompanyStruct memory newCompany = CompanyStruct({
            companyId: index,
            owner: msg.sender,
            industry: _industry,
            name: _name,
            createdAt: block.timestamp, //note might be cheaper to cache block.timstamp
            active: true,
            employees: employeesArray,
            domain: _domain,
            roles: _roles,
            powerRoles: _powerRoles
        });

        companies.push(newCompany);
        emit CompanyCreated(newCompany); // Triggering event

        // Now hire the owner as the first employee
        Employee storage employee = _employees[msg.sender];
        employee.salary = _ownerSalary;
        employee.lastPayDate = block.timestamp;
        employee.employeeId = employeesIndex;
        employee.payableAddress = msg.sender;
        employee.name = _ownerName;
        employee.companyId = index; //mh we should avoid having a company with ID == 0
        employee.role = _ownerRole;
        employee.hiredAt = block.timestamp;
        employee.active = true;
        employee.currency = _ownerCurrency;

        emit EmployeeHired(msg.sender, _ownerSalary);
        companies[index].employees.push(msg.sender);
        employeesIndex += 1;

        index += 1;
    }

    function deleteCompany(uint256 _number) public {
        require(msg.sender == companies[_number].owner);
        delete companies[_number];
        emit CompanyDeleted(companies[_number]); // Triggering event
    }

    function hireEmployee(
        address _employeeAddress,
        string memory _name,
        string memory _role,
        uint256 _companyId,
        uint256 salary,
        string memory _currency
    ) public onlyRoleWithPower(_companyId) {
        require(msg.sender == companies[_companyId].owner, "Only owner of the company can hire employee");
        bool roleExists = false; // Flag to check if role exists
        for (uint256 i = 0; i < companies[_companyId].roles.length; i++) {
            if (keccak256(abi.encodePacked(companies[_companyId].roles[i])) == keccak256(abi.encodePacked(_role))) {
                roleExists = true;
                break;
            }
        }

        require(roleExists, "Role is not present in company's roles.");

        Employee storage employee = _employees[_employeeAddress];
        employee.salary = salary;
        employee.lastPayDate = block.timestamp;
        employee.employeeId = employeesIndex;
        employee.payableAddress = _employeeAddress;
        employee.name = _name;
        employee.companyId = _companyId;
        employee.role = _role;
        employee.hiredAt = block.timestamp;
        employee.active = true;
        employee.currency = _currency;

        emit EmployeeHired(_employeeAddress, salary);
        companies[_companyId].employees.push(_employeeAddress);
        employeesIndex += 1;
    }

    function fireEmployee(
        address employeeAddress,
        // uint256 _employeeId,
        uint256 _companyId
    ) public {
        delete _employees[employeeAddress];

        emit EmployeeFired(employeeAddress);
        // remove employee from employees list
        // delete _employees[_employeeId];
        // Shift all elements to the left starting from index+1
        for (uint256 i = index; i < companies[_companyId].employees.length - 1; i++) {
            companies[_companyId].employees[i] = companies[_companyId].employees[i + 1];
        }

        // Remove the last element of the array
        companies[_companyId].employees.pop();
    }

    function payEmployee(address employeeAddress) public {
        Employee storage employee = _employees[employeeAddress];
        require(employee.salary > 0, "Employee not found");

        uint256 payPeriod = block.timestamp - employee.lastPayDate;
        uint256 payAmount = payPeriod * employee.salary;
        require(payAmount > 0, "Not enough time has passed to pay employee");

        werewolfToken.payEmployee(employeeAddress, payAmount);

        employee.lastPayDate = block.timestamp;

        emit EmployeePaid(employeeAddress, payAmount);
    }

    function payEmployees(uint256 _companyId) public {
        CompanyStruct storage _company = companies[_companyId];
        // Treasury treasury = Treasury(_treasuryAddress);

        // Check if treasury has enough balance to pay all employees
        uint256 totalPayAmount = 0;
        for (uint256 i = 0; i < _company.employees.length; i++) {
            address employeeAddress = _company.employees[i];
            Employee storage employee = _employees[employeeAddress];

            require(employee.salary > 0, "Employee not found");
            require(employee.active, "Employee not active");

            uint256 payPeriod = block.timestamp - employee.lastPayDate;

            uint256 price = tokenSale.price();
            require(price > 0, "Price cannot be zero");

            // Scale up the result by 1e18 for precision, assuming price and salary are compatible with this scale
            uint256 payAmount = (payPeriod * employee.salary * 1e18) / price;
            totalPayAmount += payAmount;
        }

        uint256 threshold = ((werewolfToken.balanceOf(_treasuryAddress) * treasury.thresholdPercentage()) / 100);

        uint256 treasuryBalance = werewolfToken.balanceOf(_treasuryAddress);

        require(totalPayAmount < threshold, "Treasury has insufficient liquidity to pay employees.");

        require(treasuryBalance > threshold, "Treasury has insufficient liquidity to pay employees.");

        // require(
        //     treasury.isAboveThreshold(),
        //     "Treasury has insufficient liquidity to pay employees."
        // );

        for (uint256 i = 0; i < _company.employees.length; i++) {
            address employeeAddress = _company.employees[i];
            Employee storage employee = _employees[employeeAddress];

            require(employee.salary > 0, "Employee not found");
            require(employee.active, "Employee not active");

            uint256 payPeriod = block.timestamp - employee.lastPayDate;

            uint256 price = tokenSale.price();
            require(price > 0, "Price cannot be zero");

            // Scale up the result by 1e18 for precision, assuming price and salary are compatible with this scale
            uint256 payAmount = (payPeriod * employee.salary * 1e18) / price;

            require(payAmount > 0, "Pay amount must be more then 0.");

            require(payPeriod > 0, "Not enough time has passed to pay employee");

            // Call the payEmployee function through the DAO contract
            werewolfToken.payEmployee(employeeAddress, payAmount);
            // Update the employee's last pay date
            employee.lastPayDate = block.timestamp;

            // Emit the EmployeePaid event
            emit EmployeePaid(employeeAddress, payAmount);
        }
    }

    function setCompanyRole(address employeeAddress, string memory newRole, uint256 _companyId) public {
        Employee storage employee = _employees[employeeAddress];
        require(employee.active, "Employee must be active");
        bool roleExists = false; // Flag to check if role exists
        for (uint256 i = 0; i < companies[_companyId].roles.length; i++) {
            if (keccak256(abi.encodePacked(companies[_companyId].roles[i])) == keccak256(abi.encodePacked(newRole))) {
                roleExists = true;
                break;
            }
        }

        require(roleExists, "Role is not present in company's roles.");

        employee.role = newRole;
    }

    function addCompanyRole(uint256 _companyId, string memory _newRole) public onlyRoleWithPower(_companyId) {
        companies[_companyId].roles.push(_newRole);
    }

    function retrieveCompany(uint256 _companyId) public view returns (CompanyStruct memory) {
        return companies[_companyId];
    }

    function retrieveEmployee(uint256 _companyId, address _employee) public view returns (Employee memory) {
        // Ensure that only the owner of the company can retrieve employee details
        require(
            msg.sender == companies[_companyId].owner, "Only the owner of the company can retrieve employee details"
        );

        // Check if the employee exists in the employees mapping
        Employee memory employee = _employees[_employee];
        require(employee.companyId == _companyId, "Employee does not belong to this company");

        return employee;
    }
}
