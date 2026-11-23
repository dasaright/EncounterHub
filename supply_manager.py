"""Conset supply configuration, price model, and EncounterHub dialog.

The desktop stores shared market settings and per-character crafting profiles;
in-game purchases and crafting are executed by the bot-side SupplyManager.au3.
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
        "trader": "Alcus Nailbiter",
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
    # Set when live prices arrive from a bot (see apply_market_prices).
    "market_updated": "",
    "market_source": "",
    # Fiber farm: craft Res Scrolls once this much fiber is stored, never spending below the reserve.
    "fiber_craft_scrolls": True,
    "fiber_scroll_threshold": 6500,
    "fiber_gold_reserve": 30000,
}

# Keys the bot writes to Config/market.prices.ini [Market] -> hub material keys.
MARKET_FILE = "market.prices.ini"
MARKET_KEYS = {
    "Bones": "bones",
    "PlantFibres": "plant_fibers",
    "Dust": "dust",
    "Feathers": "feathers",
    "Iron": "iron",
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
    result["market_updated"] = str(result["market_updated"] or "")
    result["market_source"] = str(result["market_source"] or "")
    result["fiber_craft_scrolls"] = bool(result["fiber_craft_scrolls"])
    try:
        result["fiber_scroll_threshold"] = max(25, int(result["fiber_scroll_threshold"]))
    except (TypeError, ValueError):
        result["fiber_scroll_threshold"] = DEFAULT_CONFIG["fiber_scroll_threshold"]
    try:
        result["fiber_gold_reserve"] = max(0, int(result["fiber_gold_reserve"]))
    except (TypeError, ValueError):
        result["fiber_gold_reserve"] = DEFAULT_CONFIG["fiber_gold_reserve"]
    return result


def read_market_prices(path):
    """Read live prices a bot published (Config/market.prices.ini); {} if unavailable.

    Returns {"materials": {key: price_per_10}, "ecto": int, "updated": str, "source": str}
    with only the prices that are present and positive.
    """
    import configparser
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            parser.read_file(handle)
    except (OSError, configparser.Error):
        return {}
    if not parser.has_section("Market"):
        return {}
    section = parser["Market"]

    def positive(key):
        try:
            value = int(float(section.get(key, "0")))
        except ValueError:
            return 0
        return value if value > 0 else 0

    materials = {hub_key: positive(ini_key) for ini_key, hub_key in MARKET_KEYS.items()}
    return {
        "materials": {key: value for key, value in materials.items() if value},
        "ecto": positive("Ecto"),
        "updated": section.get("Updated", "").strip(),
        "source": section.get("Source", "").strip(),
    }


def apply_market_prices(config, market):
    """Return config updated with any live prices in market (from read_market_prices)."""
    cfg = normalize_config(config)
    if not market or (not market.get("materials") and not market.get("ecto")):
        return cfg
    for key, value in market.get("materials", {}).items():
        if key in cfg["material_prices_per_10"] and value > 0:
            cfg["material_prices_per_10"][key] = int(value)
    if market.get("ecto", 0) > 0:
        cfg["ecto_price"] = int(market["ecto"])
    cfg["market_updated"] = market.get("updated", "")
    cfg["market_source"] = market.get("source", "")
    return cfg


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


def automatic_replenishment_due(total_gold, threshold):
    """The global Buy Cons trigger: bank + carried gold at or above the hub threshold."""
    return int(total_gold) >= int(threshold)


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

        def __init__(self, parent, config=None, on_save=None):
            super().__init__(parent)
            self.setWindowTitle("EncounterHub — Supply Manager")
            self.setMinimumWidth(650)
            self.config = normalize_config(config)
            self.on_save = on_save
            root = QVBoxLayout(self)

            intro = QLabel(
                "Configure the global Buy Cons settings that every farm works around, plus market prices. "
                "Choose each account's automatic and manual crafting profiles on the main Hub."
            )
            intro.setWordWrap(True)
            root.addWidget(intro)

            settings_box = QGroupBox("Production settings")
            form = QFormLayout(settings_box)
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
            form.addRow("Gold trigger (bank + carried)", self.bank_threshold)
            form.addRow("Minimum ectoplasm sale price", self.min_ecto)
            form.addRow("Automatic replenishment", self.auto_enabled)
            root.addWidget(settings_box)

            market_box = QGroupBox("Market prices")
            market = QFormLayout(market_box)
            if self.config["market_updated"]:
                live = QLabel(
                    f'Live trader prices from {self.config["market_source"] or "a bot"} '
                    f'at {self.config["market_updated"]} (bots refresh these at most once a minute).'
                )
            else:
                live = QLabel("No live prices yet: they arrive the next time a bot checks trader prices.")
            live.setWordWrap(True)
            market.addRow(live)
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
                "When enabled, every farm checks bank + carried gold after each run; at the trigger it pauses, "
                "runs the account's Automatically Craft profile until the gold is spent, then resumes. "
                "Fiber Res Scroll crafting is set in Farm Options."
            )
            self.status.setWordWrap(True)
            root.addWidget(self.status)

            buttons = QHBoxLayout()
            buttons.addStretch()
            save = QPushButton("Save Settings")
            save.clicked.connect(self.save_settings)
            close = QPushButton("Close")
            close.clicked.connect(self.reject)
            buttons.addWidget(save)
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
                "minimum_ecto_sell_price": self.min_ecto.value(),
                "ecto_price": self.ecto_price.value(),
                "ectos_per_armbrace": self.arm_rate.value(),
                "material_prices_per_10": {
                    key: field.value() for key, field in self.material_inputs.items()
                },
                "market_updated": self.config["market_updated"],
                "market_source": self.config["market_source"],
                # Fiber settings are edited in Farm Options; keep what is saved.
                "fiber_craft_scrolls": self.config["fiber_craft_scrolls"],
                "fiber_scroll_threshold": self.config["fiber_scroll_threshold"],
                "fiber_gold_reserve": self.config["fiber_gold_reserve"],
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

else:
    class SupplyDialog:
        def __init__(self, *args, **kwargs):
            raise RuntimeError("PySide6 is required for the Supply Manager dialog")
