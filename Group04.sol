// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationContract { //ตัวแปรในการจัดเก็บข้อมูลขององค์ และข้อมูลการบริจาค
    struct Organization { //เก็บข้อมูลขององค์กรที่ลงทะเบียน
        bool isRegistered; //ตรวจสอบการลงทะเบียนขององค์กร
        uint256 totalDonated; //จำนวนเงินที่องค์กรได้รับการบริจาคทั้งหมด
        uint256 totalWithdrawn; //จำนวนเงินที่องค์กรได้ถอน
        uint256 openDate; //จำนวนวันที่เปิดรับบริจาค
        string organizationName; //ชื่อขององค์กร
        string donationPurpose; //วัตถุประสงค์ในการบริจาค
    }

    struct OrgDisplay { //เก็บข้อมูลที่จะแสดงขององค์กร
        address orgAddr; //addressขององค์กร
        string name; //ชื่อองค์กร
        string purpose; //วัตถุประสงค์ในการบริจาค
        uint256 daysOpen; //จำนวนวันที่เปิดรับบริจาค
    }

    mapping(address => Organization) public organizations; 
    //เก็บข้อมูลขององค์กร โดยใช้addressขององค์กรเป็นตัวกำหนด
    mapping(address => mapping(address => uint256)) public donations;
    //เก็บข้อมูลจำนวนเงินที่ผู้บริจาคได้บริจาคให้กับแต่ละองค์กร
    mapping(address => string) public withdrawalPurpose;
    //เก็บวัตถุประสงค์ในการถอนเงินขององค์กร

    address[] private registeredOrganizations; 
    //อาเรย์ที่ใช้เก็บaddressขององค์กรที่ได้ลงทะเบียนแล้ว

    event DonationReceived(address indexed donor, address indexed organization, uint256 amount);
    //บันทึกการรับบริจาคจากผู้บริจาค
    event FundsWithdrawn(address indexed organization, uint256 amount, string purpose);
    //องค์กรทำการถอนเงิน
    event OrganizationRegistered(address indexed organization, string name, string purpose);
    //องค์กรลงทะเบียนเข้ามาในระบบ

    function registerOrganization( //การลงทะเบียนองค์กรใหม่
        address _organizationAddress, //Addressขององค์กร
        string memory _name, //ชื่อองค์กร
        string memory _donationPurpose, //วัตถุประสงค์การบริจาค
        uint256 _openDate //จำนวนวันที่เปิดรับบริจาค
    ) public {
        require(!organizations[_organizationAddress].isRegistered, "Organization already registered");

        organizations[_organizationAddress] = Organization({
            isRegistered: true,
            totalDonated: 0,
            totalWithdrawn: 0,
            openDate: _openDate,
            organizationName: _name,
            donationPurpose: _donationPurpose
        });

        registeredOrganizations.push(_organizationAddress);

        emit OrganizationRegistered(_organizationAddress, _name, _donationPurpose);
    }

    //ตรวจสอบว่าองค์กรนั้นยังไม่ได้ลงทะเบียน  
    //เก็บข้อมูลเกี่ยวกับองค์กรใน organizations และเพิ่มที่อยู่ขององค์กรใน registeredOrganizations 
    //Emit event OrganizationRegistered แจ้งการลงทะเบียนองค์กรใหม่

    function donate(address _organization) public payable { //การบริจาคเงินให้กับองค์กร
        require(msg.value > 0, "Donation must be greater than zero");
        require(organizations[_organization].isRegistered, "Organization not registered");
        //_organization: ที่อยู่ขององค์กรที่ผู้บริจาคต้องการบริจาคให้

        donations[msg.sender][_organization] += msg.value;
        organizations[_organization].totalDonated += msg.value;

        emit DonationReceived(msg.sender, _organization, msg.value);
    }
    //ตรวจสอบว่าจำนวนเงินที่บริจาคต้องมากกว่า 0
    //ตรวจสอบว่าองค์กรนั้นลงทะเบียนหรือไม่
    //เพิ่มจำนวนเงินที่บริจาคให้กับองค์กรใน donations และ totalDonated ขององค์กร
    //Emit event DonationReceived เพื่อบันทึกการบริจาค

    function withdrawFunds(uint256 amount, string memory purpose) public { //การถอนเงินจากองค์กร
        require(organizations[msg.sender].isRegistered, "Organization is not registered");
        require(bytes(purpose).length > 0, "Purpose must be specified");
        require(organizations[msg.sender].totalDonated > 0, "No funds available to withdraw");
        require(
            amount <= organizations[msg.sender].totalDonated - organizations[msg.sender].totalWithdrawn,
            "Insufficient funds"
        );
        //amount: จำนวนเงินที่ต้องการถอน
        //purpose: วัตถุประสงค์ในการถอนเงิน

        organizations[msg.sender].totalWithdrawn += amount;
        withdrawalPurpose[msg.sender] = purpose;

        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(msg.sender, amount, purpose);
    }
    //ตรวจสอบว่าองค์กรนั้นลงทะเบียนแล้ว
    // ตรวจสอบว่ามีการระบุวัตถุประสงค์ในการถอนหรือไม่
    // ตรวจสอบว่ามีเงินที่สามารถถอนออกมาได้
    // ตรวจสอบว่าเงินที่ถอนมีจำนวนไม่เกินจำนวนเงินที่บริจาคไว้
    // ทำการโอนเงินไปยังองค์กรที่ถอนเงินออกไป
    // Emit event FundsWithdrawn เพื่อบันทึกการถอนเงิน

    function getTotalDonated(address _organization) public view returns (uint256) {
        return organizations[_organization].totalDonated;
    }
    //ดึงข้อมูลจำนวนเงินที่ได้รับ*การบริจาค*และถอนเงินขององค์กร  โดยดึงที่อยู่ขององค์กรที่ต้องการดึงข้อมูล

    function getTotalWithdrawn(address _organization) public view returns (uint256) {
        return organizations[_organization].totalWithdrawn;
    }
    //ดึงข้อมูลจำนวนเงินที่ได้รับการบริจาคและ*ถอนเงิน*ขององค์กร  โดยดึงที่อยู่ขององค์กรที่ต้องการดึงข้อมูล

    function getWithdrawalPurpose(address _organization) public view returns (string memory) {
        return withdrawalPurpose[_organization];
    }
    //ดึงข้อมูลวัตถุประสงค์ในการถอนเงินขององค์กร

    function getOrganizationInfo(address _organization)
        public
        view
        returns (string memory, string memory, uint256, uint256)
    {
        Organization memory org = organizations[_organization];
        return (org.organizationName, org.donationPurpose, org.openDate, org.totalDonated);
        
    }
    ////เพื่อดึงข้อมูลขององค์กรที่ระบุ เช่น ชื่อองค์กร วัตถุประสงค์การบริจาค จำนวนวันที่รับบริจาค และจำนวนเงินที่ได้รับการบริจาค

    function getDonationInfo(address donor, address _organization) public view returns (uint256) {
        return donations[donor][_organization];
    }
    //ดึงข้อมูลจำนวนเงินที่ผู้บริจาคได้บริจาคให้กับองค์กร

    function getOrganizationByIndex(uint256 index) public view returns (OrgDisplay memory) {
        require(index < registeredOrganizations.length, "Index out of bounds");

        address orgAddr = registeredOrganizations[index];
        Organization memory org = organizations[orgAddr];

        uint256 openDays = 0;
        if (org.openDate > 0 && org.openDate < block.timestamp) {
            openDays = (block.timestamp - org.openDate) / 1 days;
        }

        return OrgDisplay({
            orgAddr: orgAddr,
            name: org.organizationName,
            purpose: org.donationPurpose,
            daysOpen: openDays
        });
    }
    //พื่อดึงข้อมูลขององค์กรที่ลงทะเบียนตามลำดับ (ตาม index) 
    //โดยจะดึงข้อมูลที่สำคัญ เช่น ชื่อองค์กร วัตถุประสงค์ และจำนวนวันที่เปิดรับบริจาค

    function getRegisteredCount() public view returns (uint256) {
        return registeredOrganizations.length;
    }
    //เพื่อดึงจำนวนองค์กรที่ได้ลงทะเบียนไว้
}


    // องค์กรที่ต้องการรับบริจาคต้องทำการลงทะเบียนผ่านฟังก์ชัน registerOrganization
    // ผู้บริจาคสามารถบริจาคเงินให้กับองค์กรผ่านฟังก์ชัน donate
    // องค์กรสามารถถอนเงินที่ได้รับการบริจาคออกมาได้ผ่านฟังก์ชัน withdrawFunds
    // ข้อมูลต่าง ๆ เกี่ยวกับองค์กรและการบริจาคสามารถตรวจสอบได้ผ่านฟังก์ชันที่มีการเรียกดูข้อมูล 
    // เช่น getTotalDonated, getDonationInfo, และ getOrganizationInfo
