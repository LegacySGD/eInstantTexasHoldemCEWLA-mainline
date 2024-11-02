<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNames)
					{
						var scenario = getScenario(jsonContext);
						var prizes = (prizeNames.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');

						// Texas Holdem Card sets
						var commCards = scenario.split("|")[0].split("+"); 				// 5 cards in the community set
						var champHand = scenario.split("|")[1].split("+"); 				// 2 Cards in the Champions Hand
						var playerHandsWithPrize = scenario.split("|")[2].split(","); 	// 2 cards in each player hand with the prize associated (e.g. A:34+21)
						var finalHands = scenario.split("|")[3].split(",");				// 5 Cards for each hand (8 hands in total), players and champ to create best hands for each. In order of best to worst.

						var DeckOfCards = [	"A,C","2,C","3,C","4,C","5,C","6,C","7,C","8,C","9,C","10,C","J,C","Q,C","K,C",
											"A,D","2,D","3,D","4,D","5,D","6,D","7,D","8,D","9,D","10,D","J,D","Q,D","K,D",
											"A,H","2,H","3,H","4,H","5,H","6,H","7,H","8,H","9,H","10,H","J,H","Q,H","K,H",
											"A,S","2,S","3,S","4,S","5,S","6,S","7,S","8,S","9,S","10,S","J,S","Q,S","K,S" ];

						var HandRanks = [ "highC", "1pair", "2pair", "3kind", "straight", "flush", "fullH", "4kind", "strFlush", "royFlush" ];
						
						var playerHands = [];
						for(var i = 0; i < playerHandsWithPrize.length; ++i)
						{
							//var secondCard = playerHandsWithPrize[i].split(":")[1].split("+")[1];
							//registerDebugText("Player [" + i + "] First Card: " + convertStringToCardTranslated(firstCard, DeckOfCards, translations));
							//registerDebugText("Player [" + i + "] Second Card: " + convertStringToCardTranslated(secondCard, DeckOfCards, translations));
							playerHands.push(playerHandsWithPrize[i].split(":")[1].split("+"));
						}


						// Community Cards
						registerDebugText("Community Cards: " + commCards);

						// Champions Hand
						registerDebugText("Champions Hand: " + champHand);			

						// Show the Player Hands
						registerDebugText("All Player Hands: " + playerHands.join("|"));
						for(var i = 0; i < playerHands.length; ++i)
						{
							registerDebugText("Player Hand [" + i + "]: " + playerHands[i]);
						}

						var winningPlayerHands = [];
						var winning = true;
						// All hands in order of best to worst
						for(var i = 0; i < finalHands.length; ++i)
						{
							var playerID = finalHands[i].split(":")[0];
							var handValue = finalHands[i].split(":")[1];
							var fullHand = finalHands[i].split(":")[2];

							if(parseInt(playerID, 10) == 0)
							{
								winning = false;
								registerDebugText("Champion has " + getHandRankTranslated(handValue, HandRanks, translations) + "!");
								continue;
							}

							if(winning == true)
							{
								winningPlayerHands.push(parseInt(playerID, 10));
								registerDebugText("Player hand " + playerID + " has Won with " + getHandRankTranslated(handValue, HandRanks, translations) + " hand!");
							}
							else
							{
								registerDebugText("Player hand " + playerID + " has Lost with " + getHandRankTranslated(handValue, HandRanks, translations) + " hand :(");
							}						
						}

						registerDebugText("Winning player Hands: " + winningPlayerHands);

						


						// Output Game Results
						var r = [];

						// Community Cards Table
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');						
						r.push('<tr><td class="tablehead" colspan="5">');
						r.push(getTranslationByName("commCards", translations));
						r.push('</td></tr>');

 							r.push('<tr>');
						for(var card = 0; card < commCards.length; ++card)
							{
								r.push('<td class="tablebody">');
							r.push(findCardInDeck(commCards[card], DeckOfCards, translations));
								r.push('</td>');
							}
 							r.push('</tr>');
 						r.push('</table>');

						// Champion Results Table
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');						
						r.push('<tr><td class="tablehead" colspan="6">');
						r.push(getTranslationByName("champion", translations));
						r.push('</td></tr>');

 							r.push('<tr>');
						r.push('<td class="tablehead">');
						r.push(getTranslationByName("startHand", translations));
						r.push('</td>');						
								r.push('<td class="tablehead" colspan="2">');
						r.push(getTranslationByName("finalHand", translations));
						r.push('</td>');
						r.push('<td class="tablehead" colspan="3">');
						r.push(getTranslationByName("handRank", translations));
								r.push('</td>');
							r.push('</tr>');

 							r.push('<tr>');
						r.push('<td class="tablebody">');
						r.push(findArrayOfCardInDeck(champHand, DeckOfCards, translations).join(", "));
						r.push('</td>');						
						r.push('<td class="tablebody" colspan="2">');
						r.push(findArrayOfCardInDeck(getHandByIndex(0, finalHands).split(":")[2].split("+"), DeckOfCards, translations).join(", "));						
						r.push('</td>');
						r.push('<td class="tablebody" colspan="3">');
						r.push(getHandRankTranslated(getHandByIndex(0, finalHands).split(":")[1], HandRanks, translations));
 								r.push('</td>');
						r.push('</tr>');						
						r.push('</table>');

						// Player Result Table
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');						
						r.push('<tr><td class="tablehead" colspan="6">');
						r.push(getTranslationByName("player", translations));
						r.push('</td></tr>');

						r.push('<tr>');
						r.push('<td class="tablehead">');
						r.push(getTranslationByName("startHand", translations));
						r.push('</td>');						
						r.push('<td class="tablehead" colspan="2">');
						r.push(getTranslationByName("finalHand", translations));
						r.push('</td>');
						r.push('<td class="tablehead">');
						r.push(getTranslationByName("handRank", translations));
						r.push('</td>');
						r.push('<td class="tablehead">');
						r.push(getTranslationByName("winner", translations));
						r.push('</td>');
						r.push('<td class="tablehead">');
						r.push(getTranslationByName("prize", translations));
								r.push('</td>');
 							r.push('</tr>');

						for(var hand = 0; hand < playerHands.length; ++hand)
								{
							var playerIndex = hand+1;
								r.push('<tr>');
							r.push('<td class="tablebody">');
							r.push(findArrayOfCardInDeck(playerHands[hand], DeckOfCards, translations).join(", "));
							r.push('</td>');							
							r.push('<td class="tablebody" colspan="2">');
							r.push(findArrayOfCardInDeck(getHandByIndex(playerIndex, finalHands).split(":")[2].split("+"), DeckOfCards, translations).join(", "));						
							r.push('</td>');
							r.push('<td class="tablebody">');
							r.push(getHandRankTranslated(getHandByIndex(playerIndex, finalHands).split(":")[1], HandRanks, translations));
							r.push('</td>');

							if(winningPlayerHands.indexOf(playerIndex) != -1)
						{
								r.push('<td class="tablebody">');
								r.push(getTranslationByName("yes", translations));
								r.push('</td>');
								r.push('<td class="tablebody">');
								r.push(convertedPrizeValues[prizes.indexOf(playerHandsWithPrize[hand].split(":")[0])]);
								r.push('</td>');						
								r.push('</tr>');
									}
							else
							{
								r.push('<td class="tablebody">');
								r.push(getTranslationByName("no", translations));
									r.push('</td>');
								r.push('<td class="tablebody"/>');							
							}						
							r.push('</tr>');
						}
						r.push('</table>');



						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
							r.push('</table>');
							
						}

						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(',');
						var prizeStructStrings = prizeStructures.split('|');

						for(var i=0; i<pricePoints.length; i++)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return '';
					}

					// Get the final hand of a player by index
					function getHandByIndex(index, hands)
					{
						for(var hand = 0; hand < hands.length; ++hand)
						{
							if(parseInt(hands[hand].split(":")[0], 10) == index)
							{
								return hands[hand];
							}
						}

						return -1;
					}

					// get the key for the hand value and translate it
					function getHandRankTranslated(handValue, hands, translations)
					{
						var handKey = hands[parseInt(handValue, 10)];
						return getTranslationByName(handKey, translations);
					}

					// Return an array of shortnamed cards based on the deck
					function findArrayOfCardInDeck(cards, deck)
					{
						var arrayOfCards = [];
						for(var i = 0; i < cards.length; ++i)
						{
							arrayOfCards.push(findCardInDeck(cards[i], deck));
						}

						return arrayOfCards;
					}

					// Return a Card shortname from Deck
					function findCardInDeck(card, deck)
					{
						var cardValue = parseInt(card, 10) - 1;						
						var type = deck[cardValue].split(",")[0];
						var suit = deck[cardValue].split(",")[1];

						return type.concat(getCardSuitHtml(suit));
					}

					// translate a card suit to html
					function getCardSuitHtml(suit)
					{
						if(suit.equals("C"))
						{
							return "&clubs;";
						}
						if(suit.equals("D"))
					{
							return "&diams;";							
					}
						if(suit.equals("H"))
					{
							return "&hearts;";
						}
						if(suit.equals("S"))
					{
							return "&spades;";
						}

						return null;
					}

					// Convert an array of cards
					function convertArrayToCardsTranslated(cards, deck, translations)
					{
						var translatedCards = [];
						for(var i = 0; i < cards.length; ++i)
						{
							translatedCards.push(convertStringToCardTranslated(cards[i], deck, translations));
							}

						return translatedCards;
						}
						
					// Card conversion
					function convertStringToCardTranslated(card, deck, translations)
					{
						//registerDebugText("Converting a Card........................." + card);
						var cardValue = parseInt(card, 10) - 1;
						//registerDebugText("Card Index: " + cardValue);						
						var type = deck[cardValue].split(",")[0];
						var suit = deck[cardValue].split(",")[1];
						//registerDebugText("Card Text Shorthand: " + type + suit);

						//registerDebugText("Card Type " + type + " converts to " + getTranslationByName(type, translations));
						//registerDebugText("Card Suit " + suit + " converts to " + getTranslationByName(suit, translations));

						//registerDebugText("Finished Converting Card........................." + card);
						return getTranslationByName(type, translations) + " - " + getTranslationByName(suit, translations);
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">

					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
