"""Conset supply configuration, price model, and EncounterHub dialog.

Game-side trading is deliberately not automated here: Encounter ReBuilt currently
exposes pause/resume controls but no supported trader, bank, or inventory API.
"""
from copy import deepcopy
import math

PROFILES = (
    "Full Conset",
    "Res Scrolls",
    "Grail of Might",
    "Armor of Salvation",
    "Essence of Celerity",
)

RECIPES = {
    "Essence of Celerity": {
        "trader": "Kwat",
        "materials": {"dust": 50, "feathers": 50},
        "fee": 250,
    },
    "Res Scrolls": {
        "trader": "Edwin",
        "materials": {"bones": 25, "plant_fibers": 25},
        "fee": 250,
    },
    "Grail of Might": {
        "trader": "Eyja",
        "materials": {"dust": 50, "iron": 50},
        "fee": 250,
    },
    "Armor of Salvation": {
        "trader": "Alcus Nailbiter",
        "materials": {"bones": 50, "iron": 50},
        "fee": 250,
    },
}

MATERIAL_LABELS = {
    "bones": "Bones",
    "plant_fibers": "Plant fibers",
    "dust": "Glittering dust",
    "feathers": "Feathers",
    "iron": "Iron ingots",
}

DEFAULT_CONFIG = {
    "automatic_enabled": False,
    "bank_gold_threshold": 800000,
    "automatic_profile": "Full Conset",
    "manual_profile": "Full Conset",
    "minimum_ecto_sell_price": 0,
    "ecto_price": 0,
    "ectos_per_armbrace": 35.0,
    # Trader prices are entered as the price for one purchase batch of 10.
    # The bot bridge will replace these manual observations with live readings.
    "material_prices_per_10": {
        "bones": 0,
        "plant_fibers": 0,
        "dust": 0,
        "feathers": 0,
        "iron": 0,
    },
}


def normalize_config(config=None):
    result = deepcopy(DEFAULT_CONFIG)
    if isinstance(config, dict):
        for key in DEFAULT_CONFIG:
            if key == "material_prices_per_10":
                values = config.get(key)
                if isinstance(values, dict):
                    for material in MATERIAL_LABELS:
                        try:
                            result[key][material] = max(0, int(values.get(material, 0)))
                        except (TypeError, ValueError):
                            pass
            elif key in config:
                result[key] = config[key]
    result["bank_gold_threshold"] = max(0, int(result["bank_gold_threshold"]))
    result["minimum_ecto_sell_price"] = max(0, int(result["minimum_ecto_sell_price"]))
    result["ecto_price"] = max(0, int(result["ecto_price"]))
    result["ectos_per_armbrace"] = max(0.01, float(result["ectos_per_armbrace"]))
    for key in ("automatic_profile", "manual_profile"):
        if result[key] not in PROFILES:
            result[key] = "Full Conset"
    result["automatic_enabled"] = bool(result["automatic_enabled"])
    return result


def material_batches(quantity, batch_size=10):
    """Number of whole trader purchases needed; partial batches are not possible."""
    if quantity < 0 or batch_size <= 0:
        raise ValueError("quantity must be non-negative and batch_size positive")
    return math.ceil(quantity / batch_size)


def recipe_cost(item, prices_per_10):
    """Return exact estimated gold cost, rounding each material up to 10-unit buys."""
    if item not in RECIPES:
        raise KeyError(item)
    total = RECIPES[item]["fee"]
    breakdown = {}
    for material, quantity in RECIPES[item]["materials"].items():
        batches = material_batches(quantity)
        try:
            batch_price = max(0, int(prices_per_10.get(material, 0)))
        except (AttributeError, TypeError, ValueError):
            batch_price = 0
        cost = batches * batch_price
        breakdown[material] = {
            "quantity": quantity,
            "batches": batches,
            "purchased_quantity": batches * 10,
            "cost": cost,
        }
        total += cost
    return {"item": item, "trader": RECIPES[item]["trader"],
            "materials": breakdown, "fee": RECIPES[item]["fee"], "total": total}


def production_costs(config):
    cfg = normalize_config(config)
    prices = cfg["material_prices_per_10"]
    return {item: recipe_cost(item, prices) for item in RECIPES}


def full_conset_cost(config):
    costs = production_costs(config)
    return sum(costs[item]["total"] for item in (
        "Essence of Celerity", "Grail of Might", "Armor of Salvation"
    ))


def ecto_equivalent(gold_cost, ecto_price):
    return None if ecto_price <= 0 else gold_cost / ecto_price


def armbrace_equivalent(gold_cost, ecto_price, ectos_per_armbrace):
    if ecto_price <= 0 or ectos_per_armbrace <= 0:
        return None
    return gold_cost / (ecto_price * ectos_per_armbrace)


def meets_manual_conset_value_limit(config):
    """Manual Full Conset may continue only when all three costs <= 80% of one ecto."""
    cfg = normalize_config(config)
    if cfg["ecto_price"] <= 0:
        return False
    return full_conset_cost(cfg) <= cfg["ecto_price"] * 0.80


def may_sell_ectoplasm(current_sell_price, minimum_sell_price):
    return int(current_sell_price) > 0 and int(current_sell_price) >= int(minimum_sell_price)


def automatic_replenishment_due(bank_gold, threshold):
    return int(bank_gold) >= int(threshold)


def choose_full_conset_component(stock):
    """Return the lowest-stock conset component, with deterministic tie ordering."""
    keys = ("Essence of Celerity", "Grail of Might", "Armor of Salvation")
    counts = {key: max(0, int(stock.get(key, 0))) for key in keys}
    return min(keys, key=lambda key: counts[key])


def may_buy_more_materials(free_inventory_slots, reserve_slots=1):
    """Keep at least one free inventory slot for the final craft/purchase."""
    return int(free_inventory_slots) > int(reserve_slots)


try:
    from PySide6.QtWidgets import (
        QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QGroupBox, QLabel,
        QPushButton, QComboBox, QSpinBox, QDoubleSpinBox, QLineEdit,
    )
except ImportError:  # Core price logic remains usable without the desktop dependency.
    QDialog = None


if QDialog is not None:
    class SupplyDialog(QDialog):
        """Configuration and transparent cost calculator; no fake game execution."""

        def __init__(self, parent, config=None, on_save=None, on_manual=None):
            super().__init__(parent)
            self.setWindowTitle("EncounterHub — Supply Manager")
            self.setMinimumWidth(650)
            self.config = normalize_config(config)
            self.on_save = on_save
            self.on_manual = on_manual
            root = QVBoxLayout(self)

            intro = QLabel(
                "Configure automatic replenishment and manual bulk production. "
                "Buy Now queues a manual run after the current farming run finishes."
            )
            intro.setWordWrap(True)
            root.addWidget(intro)

            settings_box = QGroupBox("Production settings")
            form = QFormLayout(settings_box)
            self.auto_profile = QComboBox()
            self.auto_profile.addItems(PROFILES)
            self.auto_profile.setCurrentText(self.config["automatic_profile"])
            self.manual_profile = QComboBox()
            self.manual_profile.addItems(PROFILES)
            self.manual_profile.setCurrentText(self.config["manual_profile"])
            self.bank_threshold = QSpinBox()
            self.bank_threshold.setRange(0, 2_000_000_000)
            self.bank_threshold.setGroupSeparatorShown(True)
            self.bank_threshold.setValue(self.config["bank_gold_threshold"])
            self.min_ecto = QSpinBox()
            self.min_ecto.setRange(0, 2_000_000_000)
            self.min_ecto.setGroupSeparatorShown(True)
            self.min_ecto.setValue(self.config["minimum_ecto_sell_price"])
            self.auto_enabled = QComboBox()
            self.auto_enabled.addItem("Disabled", False)
            self.auto_enabled.addItem("Enabled", True)
            self.auto_enabled.setCurrentIndex(1 if self.config["automatic_enabled"] else 0)
            form.addRow("Automatic production profile", self.auto_profile)
            form.addRow("Manual bulk profile", self.manual_profile)
            form.addRow("Bank gold trigger", self.bank_threshold)
            form.addRow("Minimum ectoplasm sale price", self.min_ecto)
            form.addRow("Automatic replenishment", self.auto_enabled)
            root.addWidget(settings_box)

            market_box = QGroupBox("Market assumptions")
            market = QFormLayout(market_box)
            self.ecto_price = QSpinBox()
            self.ecto_price.setRange(0, 2_000_000_000)
            self.ecto_price.setGroupSeparatorShown(True)
            self.ecto_price.setValue(self.config["ecto_price"])
            self.arm_rate = QDoubleSpinBox()
            self.arm_rate.setRange(0.01, 9999.0)
            self.arm_rate.setDecimals(2)
            self.arm_rate.setValue(self.config["ectos_per_armbrace"])
            market.addRow("Current Argus ecto sell price (gold)", self.ecto_price)
            market.addRow("Ectos per Armbrace (manual)", self.arm_rate)
            self.material_inputs = {}
            for key, label in MATERIAL_LABELS.items():
                field = QSpinBox()
                field.setRange(0, 2_000_000_000)
                field.setGroupSeparatorShown(True)
                field.setValue(self.config["material_prices_per_10"][key])
                self.material_inputs[key] = field
                market.addRow(label + " — price per 10", field)
            root.addWidget(market_box)

            costs_box = QGroupBox("Calculated production costs")
            costs_layout = QVBoxLayout(costs_box)
            self.cost_labels = {}
            for item in RECIPES:
                label = QLabel()
                self.cost_labels[item] = label
                costs_layout.addWidget(label)
            self.conset_label = QLabel()
            self.conset_label.setStyleSheet("font-weight:600;color:#52d4ba;")
            costs_layout.addWidget(self.conset_label)
            self.economy_label = QLabel()
            self.economy_label.setWordWrap(True)
            costs_layout.addWidget(self.economy_label)
            root.addWidget(costs_box)

            self.status = QLabel(
                "Buy Now queues a manual purchase. Automatic replenishment checks bank gold "
                "after each completed run when enabled. In-game results still need testing."
            )
            self.status.setWordWrap(True)
            root.addWidget(self.status)

            buttons = QHBoxLayout()
            buttons.addStretch()
            save = QPushButton("Save Settings")
            save.clicked.connect(self.save_settings)
            buy_now = QPushButton("Buy Now")
            buy_now.clicked.connect(self.buy_now)
            close = QPushButton("Close")
            close.clicked.connect(self.reject)
            buttons.addWidget(save)
            buttons.addWidget(buy_now)
            buttons.addWidget(close)
            root.addLayout(buttons)

            for field in [self.ecto_price, *self.material_inputs.values()]:
                field.valueChanged.connect(self.refresh_costs)
            self.arm_rate.valueChanged.connect(self.refresh_costs)
            self.refresh_costs()

        def current_config(self):
            return normalize_config({
                "automatic_enabled": self.auto_enabled.currentData(),
                "bank_gold_threshold": self.bank_threshold.value(),
                "automatic_profile": self.auto_profile.currentText(),
                "manual_profile": self.manual_profile.currentText(),
                "minimum_ecto_sell_price": self.min_ecto.value(),
                "ecto_price": self.ecto_price.value(),
                "ectos_per_armbrace": self.arm_rate.value(),
                "material_prices_per_10": {
                    key: field.value() for key, field in self.material_inputs.items()
                },
            })

        def refresh_costs(self, *_):
            cfg = self.current_config()
            costs = production_costs(cfg)
            ecto = cfg["ecto_price"]
            arms = cfg["ectos_per_armbrace"]
            for item, result in costs.items():
                e = ecto_equivalent(result["total"], ecto)
                a = armbrace_equivalent(result["total"], ecto, arms)
                e_text = "—" if e is None else f"{e:.3f} ecto"
                a_text = "—" if a is None else f"{a:.4f} Arm"
                self.cost_labels[item].setText(
                    f'{item} ({result["trader"]}): {result["total"]:,}g  |  {e_text}  |  {a_text}'
                )
            total = full_conset_cost(cfg)
            e = ecto_equivalent(total, ecto)
            a = armbrace_equivalent(total, ecto, arms)
            self.conset_label.setText(
                f"Full Conset total: {total:,}g  |  "
                f"{'—' if e is None else f'{e:.3f} ecto'}  |  "
                f"{'—' if a is None else f'{a:.4f} Arm'}"
            )
            if ecto <= 0:
                verdict = "Enter an ecto price to evaluate the 80% manual Full Conset limit."
            elif meets_manual_conset_value_limit(cfg):
                verdict = f"Manual Full Conset: within 80% limit ({ecto * .8:,.0f}g)."
            else:
                verdict = f"Manual Full Conset: STOP — cost exceeds 80% of ecto value ({ecto * .8:,.0f}g)."
            self.economy_label.setText(verdict)

        def save_settings(self):
            self.config = self.current_config()
            if self.on_save:
                self.on_save(self.config)
            self.accept()

        def buy_now(self):
            self.config = self.current_config()
            if self.on_save:
                self.on_save(self.config)
            if self.on_manual:
                self.on_manual()
            self.status.setText("Manual purchase queued. The bot will start after its current run finishes.")
else:
    class SupplyDialog:
        def __init__(self, *args, **kwargs):
            raise RuntimeError("PySide6 is required for the Supply Manager dialog")
