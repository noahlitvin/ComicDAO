const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComicDAO contract", function () {
    before(async function () {
        this.ComicCoin = await ethers.getContractFactory('ComicCoin');
        this.ComicDAO = await ethers.getContractFactory('ComicDAO');
        this.ComicGovernor = await ethers.getContractFactory('ComicGovernor');
    });

    beforeEach(async function () {
        this.dao = await this.ComicDAO.deploy();
        await this.dao.deployed();

        this.coin = await this.ComicCoin.deploy(this.dao.address);
        await this.coin.deployed();
        await this.dao.setCoinAddress(this.coin.address);

        this.governor = await this.ComicGovernor.deploy(this.coin.address);
        await this.governor.deployed();
        await this.dao.setGovernorAddress(this.governor.address);
    });

    it("should issue CMC tokens using the specified formula", async function () {
        const [owner] = await ethers.getSigners();
        await this.dao.contribute({ value: 100 });
        expect(await this.coin.balanceOf(owner.address)).to.eq("100");
    });

    it("should require ETH To propose writers and artists", async function () {
        const [owner] = await ethers.getSigners();
        //await expect(this.dao.proposeWriter()).to.be.reverted;
        //await expect(this.dao.proposeArtist()).to.be.reverted;
    });

    it("should allow a writer to be proposed, voted on, and approved.", async function () {
        const [s1, s2, s3, s4] = await ethers.getSigners();

        await this.dao.contribute({ value: 10000 });
        await this.dao.connect(s2).contribute({ value: 5000 });

        const coinCount = await this.coin.balanceOf(s1.address);
        expect(coinCount).to.eq(10000); // Voting tokens issued

        const writerAddress = "0x07Aeeb7E544A070a2553e142828fb30c214a1F86";
        await this.dao.createProposal(0, writerAddress);//, { value: ethers.utils.parseEther("0.05") });
        const proposalId = await this.dao.getProposalId(0, writerAddress);

        await ethers.provider.send('evm_mine');
        const proposalState1 = await this.governor.state(proposalId);

        expect(proposalState1).to.eq(1); // Voting is "Active"
        await expect(this.dao.executeProposal(0, writerAddress)).to.be.reverted; // We can't submit the writer yet.

        const accountVotes = await this.governor.getVotes(s1.address, 0); // Pass in current block number?
        expect(accountVotes).to.eq(10000);

        await this.governor.castVote(proposalId, 1);
        await this.governor.connect(s2).castVote(proposalId, 0);

        // let proposalVotes = await this.governor.proposalVotes(proposalId);
        // console.log(proposalVotes.map((bn) => bn.toNumber()));

        const votingPeriod = await this.governor.votingPeriod();
        for (var i = 0; i <= votingPeriod.toNumber(); i++) {
            await ethers.provider.send('evm_mine');
        }

        const proposalState2 = await this.governor.state(proposalId);
        expect(proposalState2).to.eq(4); // Proposal has "Succeeded"

        await this.dao.executeProposal(0, writerAddress);

        expect((await this.dao.writers(0))).to.eq("0x07Aeeb7E544A070a2553e142828fb30c214a1F86")
    });

    it("should allow a concept to be proposed, voted on, and approved.", async function () {
        const [s1, s2, s3, s4] = await ethers.getSigners();

        await this.dao.contribute({ value: 10000 });
        await this.dao.connect(s2).contribute({ value: 5000 });

        const coinCount = await this.coin.balanceOf(s1.address);
        expect(coinCount).to.eq(10000); // Voting tokens issued

        const conceptUri = "ipfs_uri";
        const encodedConceptURI = ethers.utils.formatBytes32String(conceptUri);
        await this.dao.createProposal(2, encodedConceptURI);//, { value: ethers.utils.parseEther("0.05") });

        const proposalId = await this.dao.getProposalId(2, encodedConceptURI);

        await ethers.provider.send('evm_mine');
        const proposalState1 = await this.governor.state(proposalId);

        expect(proposalState1).to.eq(1); // Voting is "Active"
        await expect(this.dao.executeProposal(2, encodedConceptURI)).to.be.reverted; // We can't submit the writer yet.

        const accountVotes = await this.governor.getVotes(s1.address, 0); // Pass in current block number?
        expect(accountVotes).to.eq(10000);

        await this.governor.castVote(proposalId, 1);
        await this.governor.connect(s2).castVote(proposalId, 0);

        // let proposalVotes = await this.governor.proposalVotes(proposalId);
        // console.log(proposalVotes.map((bn) => bn.toNumber()));

        const votingPeriod = await this.governor.votingPeriod();
        for (var i = 0; i <= votingPeriod.toNumber(); i++) {
            await ethers.provider.send('evm_mine');
        }

        const proposalState2 = await this.governor.state(proposalId);
        expect(proposalState2).to.eq(4); // Proposal has "Succeeded"

        await this.dao.executeProposal(2, encodedConceptURI);

        expect((await this.dao.concepts(0)).toString('utf8').replace(/\0/g, '')).to.eq(conceptUri)

    });

});