import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from supply_manager import (
    RECIPES, recipe_cost, production_costs, full_conset_cost,
    ecto_equivalent, armbrace_equivalent, meets_manual_conset_value_limit,
    may_sell_ectoplasm, automatic_replenishment_due,
    choose_full_conset_component, may_buy_more_materials,
    material_batches, normalize_config,
)


class SupplyPricingTests(unittest.TestCase):
    def setUp(self):
        self.prices = {
            "bones": 100, "plant_fibers": 200, "dust": 300,
            "feathers": 400, "iron": 500,
        }

    def test_recipes_round_materials_up_to_whole_ten_item_trader_batches(self):
        scroll = recipe_cost("Res Scrolls", self.prices)
        self.assertEqual(scroll["materials"]["bones"]["batches"], 3)
        self.assertEqual(scroll["materials"]["plant_fibers"]["purchased_quantity"], 30)
        self.assertEqual(scroll["total"], 3 * 100 + 3 * 200 + 250)

    def test_essence_recipe_and_fee(self):
        result = recipe_cost("Essence of Celerity", self.prices)
        self.assertEqual(result["total"], 5 * 300 + 5 * 400 + 250)
        self.assertEqual(result["trader"], "Kwat")

    def test_grail_and_armor_materials(self):
        costs = production_costs({"material_prices_per_10": self.prices})
        self.assertEqual(set(RECIPES["Grail of Might"]["materials"]), {"dust", "iron"})
        self.assertEqual(set(RECIPES["Armor of Salvation"]["materials"]), {"bones", "iron"})
        self.assertEqual(costs["Grail of Might"]["total"], 5 * 300 + 5 * 500 + 250)
        self.assertEqual(costs["Armor of Salvation"]["total"], 5 * 100 + 5 * 500 + 250)

    def test_full_conset_is_essence_grail_and_armor_not_scrolls(self):
        config = {"material_prices_per_10": self.prices}
        expected = sum(production_costs(config)[item]["total"] for item in (
            "Essence of Celerity", "Grail of Might", "Armor of Salvation"
        ))
        self.assertEqual(full_conset_cost(config), expected)

    def test_ecto_and_arm_equivalents(self):
        self.assertEqual(ecto_equivalent(14000, 7000), 2)
        self.assertEqual(armbrace_equivalent(14000, 7000, 35), 2 / 35)
        self.assertIsNone(ecto_equivalent(100, 0))

    def test_manual_conset_economic_ceiling_is_80_percent_of_one_ecto(self):
        config = {
            "ecto_price": 100000,
            "material_prices_per_10": {
                "bones": 0, "plant_fibers": 0, "dust": 0, "feathers": 0, "iron": 0,
            },
        }
        self.assertTrue(meets_manual_conset_value_limit(config))
        config["material_prices_per_10"]["iron"] = 8000
        self.assertFalse(meets_manual_conset_value_limit(config))

    def test_minimum_ecto_sale_price(self):
        self.assertTrue(may_sell_ectoplasm(7000, 7000))
        self.assertFalse(may_sell_ectoplasm(6999, 7000))

    def test_bank_threshold(self):
        self.assertFalse(automatic_replenishment_due(799999, 800000))
        self.assertTrue(automatic_replenishment_due(800000, 800000))

    def test_full_conset_balances_lowest_stock_component(self):
        stock = {"Essence of Celerity": 20, "Grail of Might": 15, "Armor of Salvation": 10}
        self.assertEqual(choose_full_conset_component(stock), "Armor of Salvation")

    def test_keep_one_inventory_slot_free(self):
        self.assertTrue(may_buy_more_materials(2, 1))
        self.assertFalse(may_buy_more_materials(1, 1))

    def test_batch_validation(self):
        self.assertEqual(material_batches(25), 3)
        with self.assertRaises(ValueError):
            material_batches(-1)

    def test_config_normalization_preserves_new_defaults(self):
        config = normalize_config({"bank_gold_threshold": "800000", "manual_profile": "invalid"})
        self.assertEqual(config["bank_gold_threshold"], 800000)
        self.assertEqual(config["manual_profile"], "Full Conset")
        self.assertEqual(config["ectos_per_armbrace"], 35.0)


if __name__ == "__main__":
    unittest.main()
