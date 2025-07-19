# Expert Advisor Parabolic SAR

Un Expert Advisor (EA) automatisé pour MetaTrader 4 basé sur l'indicateur Parabolic Stop-And-Reversal (SAR).

## 📋 Description

Cet EA utilise les signaux de l'indicateur Parabolic SAR pour automatiser les décisions de trading. Il ouvre des positions d'achat lorsque le SAR passe sous le prix et des positions de vente lorsque le SAR passe au-dessus du prix.

## ✨ Fonctionnalités

- **Trading automatique** basé sur les signaux Parabolic SAR
- **Fermeture automatique** des positions sur signal opposé (optionnel)
- **Gestion des risques** avec Stop Loss et Take Profit configurables
- **Trading sur nouvelle bougie** pour éviter les faux signaux
- **Magic Number** pour identifier les ordres de l'EA
- **Affichage d'informations** en temps réel sur le graphique

## ⚙️ Paramètres d'entrée

### Paramètres Parabolic SAR
- **InpSARStep** (0.02) : Pas d'accélération du SAR
- **InpSARMaximum** (0.2) : Valeur maximale d'accélération du SAR

### Paramètres de Trading
- **InpLotSize** (0.1) : Taille des lots pour les positions
- **InpMagicNumber** (12345) : Numéro magique pour identifier les ordres
- **InpSlippage** (3) : Glissement autorisé en points

### Gestion des Risques
- **InpUseStopLoss** (false) : Activer/désactiver le Stop Loss
- **InpUseTakeProfit** (false) : Activer/désactiver le Take Profit
- **InpStopLoss** (50) : Distance du Stop Loss en points
- **InpTakeProfit** (100) : Distance du Take Profit en points

### Options de Trading
- **InpTradeOnNewBar** (true) : Trader uniquement sur nouvelle bougie
- **InpCloseOnOppositeSignal** (true) : Fermer les positions sur signal opposé

## 🚀 Installation

1. Téléchargez le fichier `ParabolicSAR_EA.mq4`
2. Copiez-le dans le dossier `MQL4/Experts` de votre terminal MetaTrader 4
3. Redémarrez MetaTrader 4 ou actualisez le navigateur
4. L'EA apparaîtra dans la liste des Expert Advisors

## 📊 Utilisation

### Configuration recommandée pour débutants :